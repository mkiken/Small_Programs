# coding: utf-8

require 'date'
# ミリオンアーサー エクスタシス オートパイロット for Selenium + WebDriver
module Mae

  class Mae

    GAME_TOP_URL = 'http://x-arthur.gree-pf.net/?use_iframe=false'
    SNS_HOME_URL = 'https://id.gree.net/login/entry?ignore_sso=1&backto='
    QUEST_EMPTY      = 1

    # コンストラクタ
    def initialize
      # メインループの最大回転数（処理の回数）
      @main_loop_max = 10000000
      @expire_time = {
        QUEST_EMPTY => 15 * 60 # 体力が空になったらクエストをやらない時間
      }.freeze
      @exec_timestamp = {
        QUEST_EMPTY => nil
      }
      @const_to_str = {
        QUEST_EMPTY => 'QUEST_EMPTY'
      }
      @parameter_list = {
        'QUEST_EXEC_COUNT' => 5, #1回の行動でクエストを行う回数
        'RAID_EXEC_COUNT' => 5 #1回の行動でレイドを殴る回数
      }
    end

    # SNSにログイン
    def login_sns
      self.log 'login_sns OK'
      @driver.get SNS_HOME_URL

      self.input_text('mail', @id)
      self.input_text('user_password', @pass)

      unless self.click_element('button.large.block.primary.spacing.space15')
        self.log 'login_sns abort'
        @driver.close
      end
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
      self.login_sns # ゲームにログインしてマイページへ
      limiter = 0
      # ホーム画面で状況を確認して次の手を考えて行動する
      while limiter < @main_loop_max do
        sleep 2
        self.go_mypage
        self.log sprintf("%d's action start.", limiter)
        self.do_action limiter # 現在のページ情報から次の１手を決めて行動する
        sleep 10
        limiter += 1
      end
    end

    def go_mypage
      self.move GAME_TOP_URL
      unless self.click_element('.btn-mypage')
        self.log('go to mypage fail.')
        @driver.close
      end
    end

    # マイページの情報を精査してやるべきことをする
    def do_action(count)
      result = false
      result |= self.flash_knock # canvas ページにいるならノックして次に進む

      # レイド
      result |= self.raid_exec(@parameter_list['RAID_EXEC_COUNT'])

      sleep 3

      self.go_mypage
      # 冒険
      result |= self.quest_exec(@parameter_list['QUEST_EXEC_COUNT'])
    end

    def quest_exec(limit)
      return false if check_expire(QUEST_EMPTY)

      result = self.click_element('a.btn-quest-inner')
      # 曜日クエストに行く
      result &= self.click_element('a.tab-child-inner')
      if result
        limit.times{
          result |= self.click_element('div.quest-stage-list.margin-auto-t10')
          # ボスがいたら殴る
          if self.exist_element('a.btn-attack-0') || self.exist_element('a.btn-attack-20')
            self.vs_raidboss_exec
          end
          # 体力が残っていなかったら諦める
          if self.exist_element("//img[contains(@src, 'comeback/button_comeback.png')]", :xpath)
            self.set_expire(QUEST_EMPTY)
            return false
          end
            # ブラバ
            @driver.navigate.back
        }
      end
      result
    end

    def raid_exec(limit)
      count = 0
      while count < limit &&(self.help_raidboss_exec || self.own_raidboss_exec)
        count += 1
      end
    end

    def vs_raidboss_exec
      result = self.click_element('div.box-child > a.btn-attack-0')
      result |= self.click_element('div.box-child.padding-r10 > a.btn-attack-20')
      return result
    end

    def help_raidboss_exec
      return false unless self.click_element('div.btn-raid-rescue')
      # 未救援レイド
      raid_help_button = self.click_element('div.btn-wrap-grad-gold.width-100 > a.btn-inner.font-size-normal.bg-grad-red')
      unless raid_help_button
        return false
      end
      vs_raidboss_exec
      return true
    end

    def own_raidboss_exec
      return false unless self.click_element('div.btn-raid-appear')
      vs_raidboss_exec
    end

  end #class
end #module
