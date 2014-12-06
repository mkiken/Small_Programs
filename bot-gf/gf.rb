require 'date'
# ガールフレンド（仮） オートパイロット for Selenium + WebDriver
module GF

  class GF

    # コンストラクタ
    def initialize
      # メインループの最大回転数（処理の回数）
      @main_loop_max = 10000000
      @sns_home_url = 'http://vcard.ameba.jp/'
      @mypage_url = 'http://vcard.ameba.jp/mypage'
    end

    # メインルーチン
    def play
      self.login_ameba # ゲームにログインしてマイページへ
      limiter = 0
      # 1回だけcupid check
      self.check_cupid
      # ホーム画面で状況を確認して次の手を考えて行動する
      while limiter < @main_loop_max do
        self.log sprintf("%d's action start.", limiter)
        self.do_game_action limiter # 現在のページ情報から次の１手を決めて行動する
        sleep 2
        self.move @mypage_url # 次の処理のためにマイページへ
        sleep 10
        limiter = limiter + 1
      end
    end

    def setting(driver, id, pass, max_count)
      # Selenium WebDriver をセットする（必須）
      @driver = driver
      # SNS の ID をセット。GREE はメールアドレス
      @id = id
      # SNS の password をセット。
      @pass = pass
      # メインループの最大回転数を変更する
      @main_loop_max = max_count
    end

    def login_ameba
      self.move @sns_home_url
      sleep 1
      self.click_element('button.btn.large.primary')
      sleep 1
      self.input_text('username', @id)
      self.input_text('password', @pass)
      self.click_element('button#submit.btn.large.primary')
      self.log "login success! " + @id
      sleep 2
      self.move @mypage_url
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

    def click_element(target_css)
      begin
        target_btn = @driver.find_element(:css, target_css)
        target_btn.click
      rescue
        self.log "invalid target_css => " + target_css
        return FALSE
      end
      self.log "jump to => " + target_css
      sleep 1
      return TRUE
    end

    def click_link(target_text)
      begin
        target_link = @driver.find_element(:link_text, target_text)
        target_link.click
      rescue
        self.log "invalid target_link => " + target_text
        return FALSE
      end
      self.log "jump to => " + target_text
      sleep 1
      return TRUE
    end

    # マイページの情報を精査してやるべきことをする
    def do_game_action(count)
      self.flash_knock # canvas ページにいるならノックして次に進む

      self.check_smile_cupid # スマイルキューピッド
      self.check_arbeit # アルバイト

      # 出現中だったらレイドに攻撃
      self.raidboss_appear_exec

      # クエストを走る
      self.quest_exec

    end

    def check_cupid
      self.log "check_cupid start."
      self.click_element('#mail')
      if self.click_link('無料キューピッドが引けます')
        sleep 1
        self.click_link('無料でお願い♪キューピッド')
        sleep 10
        self.flash_knock
      end
      self.log "check_cupid end."
      self.move @mypage_url
    end

    def check_smile_cupid
      self.log "check_smile_cupid start."
      self.click_element('#mail')
      if self.click_link('スマイルキューピッドを引こう')
        sleep 1
        self.click_link('無料でお願い♪キューピッド')
        sleep 10
        self.flash_knock
      end
      self.log "check_smile_cupid end."
      self.move @mypage_url
    end

    def check_arbeit
      self.log "check_arbeit start."
      self.click_element('#mail')
      if self.click_link('アルバイトが終了しました')
        sleep 1
        self.click_link('引き続きバイトをする')
        sleep 10
        self.flash_knock
      end
      self.log "check_arbeit end."
      self.move @mypage_url
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
      p Time.now.strftime('[%Y-%m-%d %H:%M:%S]') + ':' + message
    end

    def quest_exec
      self.log "quest_exec start."
      self.flash_knock
      if self.click_element('#js_questBtn>a') == FALSE
        self.log "quest button not found. quest_exec end."
        return;
      end

      # 通常時
      while(self.click_element('#btnFight'))
        sleep 3
      end
      # 特別時
      while(self.click_element('div.js_btnEffect'))
        sleep 3
      end
      self.log "quest_exec end."
    end

    def raidboss_appear_exec
      self.log "raidboss_appear_exec start."
      if self.click_element('p.raidBossAppear')
        while self.click_link('救出する')
          if self.click_element('div.sprite1_battleBtn11')
            self.flash_knock
          else
            # 救出が無理だったら諦める
            break
          end
        end
      end
      self.log "raidboss_appear_exec end."
      self.move @mypage_url
    end
  end
end
