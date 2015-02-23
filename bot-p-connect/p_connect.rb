# coding: utf-8

require 'date'
# プリンセスコネクト オートパイロット for Selenium + WebDriver
module P_connect

  class P_connect

    TOP_URL        = 'http://astrum.amebagames.com/'

    # コンストラクタ
    def initialize
      # メインループの最大回転数（処理の回数）
      @main_loop_max = 10000000
      # @expire_time = {
      # }.freeze
      # @exec_timestamp = {
      # }
      # @const_to_str = {
      # }
    end

    def setting(driver, id, pass, max_count)
      # Selenium WebDriver をセットする（必須）
      @driver = driver
      # SNS の ID をセット。
      @id = id
      # SNS の password をセット。
      @pass = pass
      # メインループの最大回転数を変更する
      @main_loop_max = max_count
    end

    def move(url)
      begin
        @driver.navigate.to url
        self.log "moved to #{url}"
      rescue
        self.log "couldn't move to #{url}..."
      end
    end

    def input_text(field_id, text)
      element = self.find_element(field_id, :name)
      if element.nil?
        raise ArgumentError, "invalid field_id =>" + field_id
      end
      element.clear
      element.send_keys(text)
    end


    def exist_element(target_css, selector=:css, display_check = false)
      begin
        target = self.find_element(target_css, selector)
        if target.nil?
          return false
        end
        if display_check
          return false unless target.displayed?
        end
      rescue
        return false
      end
      self.log "exist target_css element => " + target_css
      true
    end

    def click_element(target_css, selector=:css)
      begin
        target_btn = self.find_element(target_css, selector)
        target_btn.click
      rescue
        self.log "click fail. invalid target => " + target_css
        return false
      end
      self.log "jump to => " + target_css
      sleep 1
      true
    end

    def click_link(target_text)
      return self.click_element(target_text, :link_text)
    end

    def set_expire(key)
      @exec_timestamp[key] = Time.now
      self.log "set_expire, key=#{@const_to_str[key]}, execute_time=#{@exec_timestamp[key]}"
    end

    def remove_expire(key)
      @exec_timestamp[key] = nil
      self.log "remove_expire, key=#{@const_to_str[key]}"
    end

    # trueならまだ有効期限内
    def check_expire(key)
      self.log "check_expire, key=#{@const_to_str[key]}, execute_time=#{@exec_timestamp[key]}"
      return false if @exec_timestamp[key].nil?
      now = Time.now
      diff = (now - @exec_timestamp[key]).to_i.abs
      diff < @expire_time[key] ? true : false
    end


    # canvas 要素があるみたいならノックして次の画面へ
    def flash_knock(count=1)
      begin
        current_url = @driver.current_url
        canvas = self.find_element('#canvas')
        if canvas
          cnt = 0 # 無限ループ対策
          while current_url == @driver.current_url and cnt <= 10 do
            count.times{
              canvas.click
              sleep 1
            }
            cnt += 1
          end
        end
      rescue
      ensure
        sleep 2 # 画面遷移用にちょっと待つ
      end
    end

    # コンソール出力
    def log(message)
      p "#{Time.now.strftime('[%Y-%m-%d %H:%M:%S]')}: #{message}"
    end

    def find_element(target, selector = :css)
      return @driver.find_element(selector, target)
    end

    def find_elements(target, selector = :css)
      return @driver.find_elements(selector, target)
    end


    # メインルーチン
    def play
      self.login # ゲームにログインしてマイページへ
      limiter = 0
      # ホーム画面で状況を確認して次の手を考えて行動する
      while limiter < @main_loop_max do
        self.log sprintf("%d's action start.", limiter)
        self.do_action limiter # 現在のページ情報から次の１手を決めて行動する
        sleep 2
        self.move TOP_URL
        sleep 10
        limiter += 1
      end
    end

    def login
      self.move TOP_URL
      sleep 1
      self.click_element('input.btn.btn_primary.large')
      sleep 1
      self.input_text('username', @id)
      self.input_text('password', @pass)
      self.click_element('input#login_button')
      self.log "login success! " + @id
      sleep 2
    end

    # マイページの情報を精査してやるべきことをする
    def do_action(count)
      result = false
      result |= self.flash_knock # canvas ページにいるならノックして次に進む

      # TODO 一日一回無料ガチャ

      # レイド
      result |= self.raid_exec

      sleep 3

      # 冒険
      result |= self.quest_exec(5)
    end

    def quest_exec(limit)

      unless self.exist_element('div.menu-quest') and self.click_element('div.menu-quest')
        self.log 'quest button not found!'
        return false
      end
      unless self.exist_element('div.map_areas-column.ps-mlra.ps-mb12.js-map-column.bztch-tap') and self.click_element('div.map_areas-column.ps-mlra.ps-mb12.js-map-column.bztch-tap')
        self.log 'quest stage not found!'
        return false
      end
      sleep 1
      count = 0
      result = false

      # ステージボス
      if self.exist_element('div.areaboss-btn-action')
        result |= self.click_element('div.areaboss-btn-action')
        sleep 5
      end

      while count < limit and self.exist_element('div.stage-btn-action')
        result |= self.click_element('div.stage-btn-action')
        sleep 3
        count += 1
      end
      sleep 1
      result
    end

    def raid_exec
      return false unless self.exist_element('div.menu-raid')
      return false unless self.click_element('div.menu-raid')
      sleep 1
      result =  self.help_raidboss_exec || self.own_raidboss_exec
      self.move TOP_URL
      return result
    end

    def own_raidboss_exec
      unless self.exist_element('div.ps-deco-btn_m.ps-deco-btn-accent2_m.ps-mr8.bztch-tap')
        self.log "not found own raidboss!"
        return false
      end
      return false unless self.click_element('div.ps-deco-btn_m.ps-deco-btn-accent2_m.ps-mr8.bztch-tap')
      return self.attack_raid_exec
    end

    def attack_raid_exec
      # TODO 可能なら全力攻撃すべき？
      # 0BP攻撃
      if self.exist_element('div.ps-deco-btn_m.ps-deco-btn-accent2_m.hud-btn-attack0')
      return false unless self.click_element('div.ps-deco-btn_m.ps-deco-btn-accent2_m.hud-btn-attack0')
        # 通常攻撃
      elsif self.exist_element('div.ps-deco-btn_m.ps-deco-btn-normal_m.ps-mr8.hud-btn-attack1')
        return false unless self.click_element('div.ps-deco-btn_m.ps-deco-btn-normal_m.ps-mr8.hud-btn-attack1')
      else
        self.log "can't attack on your bp."
        return false
      end
      sleep 3
      true
    end

    def help_raidboss_exec
      raid_buttons = self.find_elements('div.ps-deco-btn_m.ps-deco-btn-accent2_m.bztch-tap')
      target_button = nil
      raid_buttons.each{ |e|
        target_button = e if e.text == "救援に向かう"
      }
      if target_button.nil?
        self.log "not found help raidboss!"
        return false
      end
      target_button.click
      return false unless self.exist_element('div.ps-deco-btn_l.ps-deco-btn-accent2_l.ps-mlra.bztch-tap')
      # TODO 新しい依頼優先で殴る
      # ランダムに殴る
      help_list = self.find_elements('div.ps-deco-btn_l.ps-deco-btn-accent2_l.ps-mlra.bztch-tap')
      index = rand(help_list.length)
      help_list[index].click
      sleep 1
      return self.attack_raid_exec
    end

  end #class
end #module
