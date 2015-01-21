# coding: utf-8

require 'date'
# ドラゴンプロヴィデンス オートパイロット for Selenium + WebDriver
module D_prov

  class D_prov

    DMM_HOME_URL   = 'http://www.dmm.co.jp/netgame/social/-/gadgets/=/app_id=103147/1st=1/'

    # コンストラクタ
    def initialize
      # メインループの最大回転数（処理の回数）
      @main_loop_max = 10000000
      @expire_time = {
      }.freeze
      @exec_timestamp = {
      }
      @const_to_str = {
      }
    end

    # メインルーチン
    def play
      self.login_dmm # ゲームにログインしてマイページへ
      limiter = 0
      # ホーム画面で状況を確認して次の手を考えて行動する
      while limiter < @main_loop_max do
        self.log sprintf("%d's action start.", limiter)
        self.do_game_action limiter # 現在のページ情報から次の１手を決めて行動する
        sleep 2
        self.move MYPAGE_URL # 次の処理のためにマイページへ
        sleep 10
        limiter = limiter + 1
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

      a = @driver.find_element(:tag_name, "iframe")
      @driver.switch_to().frame(a);
      # a = @driver.find_element(:tag_name, "iframe")
      # p a
      # tmp = '#game_frame'
      # if self.exist_element(tmp)
        # self.log "#{tmp} found."
      # else
        # self.log "not found."
      # end
      # @driver.switch_to().frame("center_iframe");
      # tmp = @driver.find_elements(:tag_name, "iframe")
      # self.log(tmp.length)
      # @driver.switch_to().frame(@driver.find_elements(:tag_name, "iframe")[1])
      # @driver.switch_to().frame(@driver.find_elements(:tag_name, "iframe")[0])
      unless self.click_element("div#toppageMain")
        self.log "couldn't move to mypage. exit."
        exit
      end
      # self.click_element("//a[contains(@href, 'http://www.drapro.dmmgames.com/mypage')]", :xpath)
    end

    def move(url)
      @driver.navigate.to url
      self.log "moved to " + url
    end

    def input_text(field_id, text)
      element = @driver.find_element(:name, field_id)
      if element.nil?
        raise ArgumentError, "invalid field_id =>" + field_id
      end
      element.clear
      element.send_keys(text)
    end


    def exist_element(target_css, selector=:css)
      begin
        target = @driver.find_element(selector, target_css)
        if target.nil?
          return false
        end
      rescue
        return false
      end
      self.log "exist target_css element => " + target_css
      true
    end

    def click_element(target_css, selector=:css)
      begin
        target_btn = @driver.find_element(selector, target_css)
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
    def do_game_action(count)
      self.flash_knock # canvas ページにいるならノックして次に進む

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
        canvas = @driver.find_element(:css, '#canvas')
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

  end #class
end #module
