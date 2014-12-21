# coding: utf-8

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
      self.raidboss_appear_hunters_exec

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

    def quest_exec
      self.log "quest_exec start."
      return if self.check_expire QUEST_EMPTY #期限内だったらやらない
      self.flash_knock

      if self.click_element('#js_questBtn>a') == FALSE
        self.log "quest button not found. quest_exec end."
        return FALSE
      end

      # 通常時
      if self.quest_normal_check
        ret =  self.quest_normal_exec
      # おねがいハンターズ
      elsif self.quest_hunters_check
        ret = self.quest_hunters_exec
      else
        # なかったら悪xxレイドイベントと仮定して走ってみる
        ret = self.quest_raidevent_exec
      end
      self.log "quest_exec end."
      ret
    end

    # レイドイベントボス出現中なら倒す
    def raidboss_appear_exec
      self.log "raidboss_appear_exec start."
      return if self.check_expire RAIDBOSS_EMPTY #期限内だったらやらない
      if self.click_element('p.raidBossAppear')
        while self.click_link('救出する')
          break unless self.vs_raidboss_exec('div.sprite1_battleBtn11', 'a.btn.btnPrimary.w96.jsTouchActive.battleBtn.relative.btnDisabled') # 救出が無理だったら諦める
        end
      end
      self.log "raidboss_appear_exec end."
      self.move MYPAGE_URL
    end

    # お願いハンターズのレイドイベントボス出現中なら倒す
    def raidboss_appear_hunters_exec
      self.log "raidboss_appear_hunters_exec start."
      return if self.check_expire RAIDBOSS_EMPTY #期限内だったらやらない
      if self.exist_element("//a[contains(@href, '/raidwar/status?eventId=')]", :xpath) #Touchボタンがあったら
        # if self.click_element("//div/a[contains(@href, '/raidwar/status?eventId=')]", :xpath)
        if self.click_element("//img[contains(@src, 'boss_appear.png')]", :xpath)
          while self.click_link('捕まえる')
            break unless self.vs_raidboss_exec('a.btn.btn.btnPrimary.jsTouchActive.battleBtn', '#js_pushCandyPower') # 救出が無理だったら諦める
          end
        end
        self.move MYPAGE_URL
      end

      self.log "raidboss_appear_hunters_exec end."
    end

    # なんらかのアクションに成功したらTRUE
    def vs_raidboss_exec(btn_css, expire_css)
      self.log "vs_raidboss_exec start."
      help_request = self.request_help
      battle_done = FALSE
      while self.click_element(btn_css)
        self.flash_knock
        battle_done = TRUE
      end
      help_request |= self.request_help
      self.set_expire RAIDBOSS_EMPTY if self.exist_element(expire_css) #point切れたらexpireセット
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

    # 通常時クエスト
    def quest_normal_check
      self.exist_element("img[src='http://stat100.ameba.jp/vcard/ratio20/images/title/area_h1.jpg']")
    end

    def quest_normal_exec
      self.log "quest_normal_exec start."
      # 通常時はquest_detailに飛ばないとクエストができない
      if ! self.click_element("img[src='http://stat100.ameba.jp/vcard/ratio20/images/quest/btn_challenge.png']")
        self.log "Now you're in area select page. But quest btn not found!"
        return FALSE
      end
      self.run_quest
      self.log "quest_normal_exec end."
    end

    # おねがいハンターズ
    def quest_hunters_check
      # おねがいハンターズ時はquest_detailに飛ばないとクエストができない
      self.exist_element("//a[contains(@href, '/raidwar/quest/detail?eventId=')]", :xpath) #Touchボタンがあったら
    end

    def quest_hunters_exec
      self.log "quest_hunters_exec start."
      if ! self.click_element("//a[contains(@href, '/raidwar/quest/detail?eventId=')]", :xpath)
        self.log "Now you're in raid event page. But quest btn not found!"
        return FALSE
      end
      self.run_quest('#js_btnFight')
      self.log "quest_hunters_exec end."

    end

    def quest_raidevent_exec
      self.log "quest_raidevent_exec start."
      self.run_quest
      self.log "quest_raidevent_exec end."
    end

    def run_quest(btn_id = '#btnFight')
      # 通常時
      while(self.click_element(btn_id))
        sleep 3
        # もし3秒経ってもボタンが有効になってなかったら終了
        if self.exist_element('#btnFight.relative.noneTapColor.sprite2_btnSearchOff') ||
          self.exist_element('#btnFight.relative.noneTapColor.sprite2_btnSearchUpoff') ||
          self.exist_element('#btnFight.sprite1_btnFightOff') ||
          self.exist_element('#js_btnFight.inlineBlock.btnFight.btnFightOff')
          break
        end

        # TODO Touch Bonus
        # if self.exist_element("//div[@id='bustUpGirlBtn' and @class='btnBlueGrn' and contains(@style, 'position')]", :xpath) #Touchボタンがあったら
          # self.log "Touch start!"
          # # style="position: absolute; width: 131px; height: 53px; overflow: hidden; left: 167px; top: 213px; background-image: url(http://stat100.ameba.jp/vcard/ratio20/images/animation/quest/touchbonus/common_voiceAlertOffBtn.png); background-position: 0px 0px;"のdiv要素（音声OFFのまま）をクリック
          # self.flash_knock(4)
          #position: absolute; width: 271px; height: 53px; overflow: hidden; left: 25px; top: 308px; background-image: url(http://stat100.ameba.jp/vcard/ratio20/images/animation/quest/touchbonus/resultQuestBtn.png); background-position: 0px 0px;（登校にもどる）をクリック,最悪リダイレクト

        # end

        # TODO 判定のロジックがあまり良くないので変えたい
        # TODO 通常クエスト時に上手く空判定が出来ていない
        self.set_expire QUEST_EMPTY if self.exist_element("//div[@id='outStamina' and @class='popup' and contains(@style, 'position')]", :xpath) #体力切れたらexpireセット
      end
      TRUE
    end
  end
end
