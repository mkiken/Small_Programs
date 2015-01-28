# coding: utf-8

require 'date'
# ドラゴンプロヴィデンス オートパイロット for Selenium + WebDriver
module D_prov

  class D_prov

    DMM_HOME_URL   = 'http://www.dmm.co.jp/netgame/social/-/gadgets/=/app_id=103147/1st=1/'
    TOP_URL        = 'http://www.drapro.dmmgames.com/top/index/t'

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

    # メインルーチン
    def play
      self.login_dmm # ゲームにログインしてマイページへ
      limiter = 0
      # ホーム画面で状況を確認して次の手を考えて行動する
      while limiter < @main_loop_max do
        self.log sprintf("%d's action start.", limiter)
        self.do_action limiter # 現在のページ情報から次の１手を決めて行動する
        sleep 2
        self.go_to_mypage
        sleep 10
        limiter += 1
      end
    end

    def go_to_mypage
      self.log 'go_to_mypage.'
      self.move TOP_URL
      unless self.click_element("//img[contains(@src, 'http://www.drapro.dmmgames.com/img/image/sp/ui/top/default/')]", :xpath)
        self.log "couldn't move to mypage."
        # exit
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

    def login_dmm
      self.move DMM_HOME_URL
      sleep 1
      self.input_text('login_id', @id)
      self.input_text('password', @pass)
      self.click_element('span.d-btn-la-hi')
      self.log "login success! #{@id}"
      sleep 1

      self.switch_target_frame('#game_frame')
      self.move_to_center_frame
      self.switch_target_frame('#center_iframe')
      self.move_to_center_frame
      self.go_to_mypage
    end

    # frameのsrc要素に無理やり飛ぶ
    def move_to_center_frame
      self.jump_to_unclickable_link('#center_iframe', 'src')
    end

    # クリックできないリンクを属性から無理やり飛ぶ
    def jump_to_unclickable_link(target_element, target_attribute = 'href')
      return false unless self.exist_element(target_element)
      target = self.find_element(target_element)
      if target.nil?
        self.log "not found => [#{target_element}], #{__method__}"
        return false
      end
      self.move target.attribute(target_attribute)
      return true
    end

    def switch_target_frame(frame_name)
      target_frame = self.find_element(frame_name)
      @driver.switch_to().frame(target_frame);
      self.log "switch frame to #{frame_name}"
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

    # マイページの情報を精査してやるべきことをする
    def do_action(count)
      self.flash_knock # canvas ページにいるならノックして次に進む

      self.own_raidboss_exec
      self.help_raidboss_exec
      self.quest_exec

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
      self.log 'flash_knock start.'
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
      self.log 'flash_knock end.'
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

    def quest_exec
      self.log "#{__method__} start."
      return false unless self.jump_to_unclickable_link('a.search')
      return false unless self.jump_to_unclickable_link('a.btnMR.push-motion0')

      # story flash対応
      if self.exist_element('div#pnovel-click-area.pnovel-click-area')
        count = 0
        while self.click_element('div#pnovel-click-area.pnovel-click-area')
          count += 1
          self.log "click story flash : #{count}."
          sleep 3
        end
      end

      # ステージボスが出ていたら攻撃
      self.log "attack to area boss." if self.jump_to_unclickable_link('a.btnLR.push-motion0')

      self.log "#{__method__} end."
      self.go_to_mypage
    end

    # 自発レイド
    def own_raidboss_exec
      self.log "#{__method__} start."
      return false unless self.jump_to_unclickable_link('li#mypageNavRaidBoss > a')
      self.vs_raidboss_exec
      self.log "#{__method__} end."
      self.go_to_mypage
    end

    # 救援依頼
    def help_raidboss_exec
      self.log "#{__method__} start."
      return false unless self.jump_to_unclickable_link('li#mypageNavRaidRescue > a')
      # 新規ボス優先で倒しに行く
      return false unless self.jump_to_unclickable_link('article.raidList.new > div.btn.marT10.marB5 > a') or self.jump_to_unclickable_link('article.raidList > div.btn.marT10.marB5 > a')
      self.vs_raidboss_exec
      self.log "#{__method__} end."
      self.go_to_mypage
    end

    def vs_raidboss_exec
      # 救援要請が出せたら出す
      if self.jump_to_unclickable_link('a#onHelpRequest')
        return false unless self.jump_to_unclickable_link('ul.linkList.arrowL > li > a')
        self.log 'request raid help.'
      end

      if self.exist_element('#raidNew-btnAttackFree', :css, true)
        js = <<'JSFREE'
Raidboss.args.isNew = 0;
Raidboss.battleExec(1);
JSFREE
        @driver.execute_script js;
        self.log "free attack!"
      elsif self.exist_element('#raidNew-btnAttack20', :css, true)
        js = <<"JS20"
if (! Raidboss.dom.btnAttack20.hasClass("off")) {
    Raidboss.battleExec(2);
}
JS20
        @driver.execute_script js;
        self.log "ap-20 attack!"
      else
        self.log "button not found. return."
        return false
      end
    end

  end #class
end #module
