require 'date'
# ガールフレンド（仮） オートパイロット for Selenium + WebDriver
module GF

  class GF

    FREE_CUPID = 1
    SMILE_CUPID = 2
    ARBEIT = 3
    QUEST_EMPTY = 4
    RAIDBOSS_EMPTY = 5
    AMEBA_HOME_URL = 'http://vcard.ameba.jp/'
    MYPAGE_URL = 'http://vcard.ameba.jp/mypage'

    # コンストラクタ
    def initialize
      # メインループの最大回転数（処理の回数）
      @main_loop_max = 10000000
      @expire_time = {
        FREE_CUPID => 60 * 60 * 24, # 無料キューピッドは1日
        SMILE_CUPID => 60 * 60 * 8, # スマイルキューピッドは8時間
        ARBEIT => 60 * 60, # アルバイトは1時間
        QUEST_EMPTY => 60 * 20, #クエストはとりあえず20分にしてみる
        RAIDBOSS_EMPTY => 60 * 3 #レイドはとりあえず3分にしてみる
      }.freeze
      @exec_timestamp = {
        FREE_CUPID => nil,
        SMILE_CUPID => nil,
        ARBEIT => nil,
        QUEST_EMPTY => nil,
        RAIDBOSS_EMPTY => nil,
      }
    end

    # メインルーチン
    def play
      self.login_ameba # ゲームにログインしてマイページへ
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

    def login_ameba
      self.move AMEBA_HOME_URL
      sleep 1
      self.click_element('button.btn.large.primary')
      sleep 1
      self.input_text('username', @id)
      self.input_text('password', @pass)
      self.click_element('button#submit.btn.large.primary')
      self.log "login success! " + @id
      sleep 2
      self.move MYPAGE_URL
    end

    def move(url)
      @driver.navigate.to url
      self.log "move to " + url
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
          return FALSE
        end
      rescue
        return FALSE
      end
      self.log "exist target_css element => " + target_css
      TRUE
    end

    def click_element(target_css, selector=:css)
      begin
        target_btn = @driver.find_element(selector, target_css)
        target_btn.click
      rescue
        self.log "invalid target => " + target_css
        return FALSE
      end
      self.log "jump to => " + target_css
      sleep 1
      TRUE
    end

    def click_link(target_text)
      return self.click_element(target_text, :link_text)
    end

    # マイページの情報を精査してやるべきことをする
    def do_game_action(count)
      self.flash_knock # canvas ページにいるならノックして次に進む

      self.check_free_cupid # 無料キューピッド
      self.check_smile_cupid # スマイルキューピッド
      self.check_arbeit # アルバイト

      # 出現中だったらレイドに攻撃
      self.raidboss_appear_exec

      # クエストを走る
      self.quest_exec

    end

    def set_expire(key)
      @exec_timestamp[key] = Time.now
      self.log "set_expire, key=#{key}, execute_time=#{@exec_timestamp[key]}"
    end

    # TRUEならまだ有効期限内
    def check_expire(key)
      self.log "check_expire, key=#{key}, execute_time=#{@exec_timestamp[key]}"
      return FALSE if @exec_timestamp[key].nil?
      now = Time.now
      diff = (now - @exec_timestamp[key]).to_i.abs
      diff < @expire_time[key] ? TRUE : FALSE
    end

    def check_free_cupid
      self.log "check_free_cupid start."
      return if self.check_expire FREE_CUPID #期限内だったらやらない
      self.set_expire FREE_CUPID
      self.click_element('#mail')
      if self.click_link('無料キューピッドが引けます')
        sleep 1
        self.click_link('無料でお願い♪キューピッド')
        sleep 10
        self.flash_knock
      end
      self.log "check_free_cupid end."
      self.move MYPAGE_URL
    end

    def check_smile_cupid
      self.log "check_smile_cupid start."
      return if self.check_expire SMILE_CUPID #期限内だったらやらない
      self.set_expire SMILE_CUPID
      self.click_element('#mail')
      if self.click_link('スマイルキューピッドを引こう')
        sleep 1
        self.click_link('無料でお願い♪キューピッド')
        sleep 10
        self.flash_knock
      end
      self.log "check_smile_cupid end."
      self.move MYPAGE_URL
    end

    # TODO 動作未確認
    def check_arbeit
      self.log "check_arbeit start."
      return if self.check_expire ARBEIT #期限内だったらやらない
      self.set_expire ARBEIT
      self.click_element('#mail')
      if self.click_link('アルバイトが終了しました')
        sleep 10
        self.click_element('p.js_closeBtn.closePopBtn') #Amebaポイントのポップアップ消去
        sleep 1
        self.click_link('引き続きバイトをする')
        sleep 7 # ポップアップが出ている確率をあげるため少し長めに取る
        self.click_element('a#accompanySubmitBtn.btnPink.w135')
        self.flash_knock
      end
      self.log "check_arbeit end."
      self.move MYPAGE_URL
    end


    # canvas 要素があるみたいならノックして次の画面へ
    def flash_knock
      self.log 'flash_knock start.'
      begin
        current_url = @driver.current_url
        canvas = @driver.find_element(:css, '#canvas')
        if canvas
          while current_url == @driver.current_url do
            canvas.click
            sleep 2
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

    def quest_exec
      self.log "quest_exec start."
      return if self.check_expire QUEST_EMPTY #期限内だったらやらない
      self.flash_knock
      if self.click_element('#js_questBtn>a') == FALSE
        self.log "quest button not found. quest_exec end."
        return FALSE
      end

      # 通常時
      while(self.click_element('#btnFight'))
        sleep 3
        # もし3秒経ってもボタンが有効になってなかったら終了
        if self.exist_element('#btnFight.relative.noneTapColor.sprite2_btnSearchOff') || self.exist_element('#btnFight.relative.noneTapColor.sprite2_btnSearchUpoff')
          break
        end

        # TODO 判定のロジックがあまり良くないので変えたい
        self.set_expire QUEST_EMPTY if self.exist_element("//div[@id='outStamina' and @class='popup' and contains(@style, 'position')]", :xpath) #体力切れたらexpireセット
      end
      self.log "quest_exec end."
      TRUE
    end

    def raidboss_appear_exec
      self.log "raidboss_appear_exec start."
      return if self.check_expire RAIDBOSS_EMPTY #期限内だったらやらない
      if self.click_element('p.raidBossAppear')
        while self.click_link('救出する')
          break unless self.vs_raidboss_exec # 救出が無理だったら諦める
        end
      end
      self.log "raidboss_appear_exec end."
      self.move MYPAGE_URL
    end

    # なんらかのアクションに成功したらTRUE
    def vs_raidboss_exec
      self.log "vs_raidboss_exec start."
      help_request = self.request_help
      battle_done = FALSE
      while self.click_element('div.sprite1_battleBtn11')
        self.flash_knock
        battle_done = TRUE
      end
      help_request |= self.request_help
      self.set_expire RAIDBOSS_EMPTY if self.exist_element("a.btn.btnPrimary.w96.jsTouchActive.battleBtn.relative.btnDisabled") #point切れたらexpireセット
      self.log "vs_raidboss_exec end."
      help_request | battle_done
    end

    # お助け依頼を出せれば出す
    def request_help
      help_request = self.click_link('オススメでお助け依頼をする') # 部員だけの方がよかったりする？
      if help_request
        help_request = self.click_element('#js_rescueUpCloseButton')
      end
      help_request
    end
  end
end
