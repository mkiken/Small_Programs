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
    DEFAULT_MAX_BEAT = 4

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
          return false
        end
      rescue
        return false
      end
      self.log "exist target_css element => " + target_css
      true
    end

    def is_disabled(obj)
    end

    def click_element(target_css, selector=:css)
      begin
        target_btn = @driver.find_element(selector, target_css)
        # unless target_btn.enabled?
          # self.log "target [#{target_css}] found. but it's disabled."
          # return false
        # end
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

      self.check_free_cupid # 無料キューピッド
      self.check_smile_cupid # スマイルキューピッド
      self.check_arbeit # アルバイト

      # 出現中だったらレイドに攻撃
      while true
        break unless
          self.raidboss_appear_exec or
          self.raidboss_appear_hunters_exec or
          self.help_exec
      end

      # クエストを走る
      self.quest_exec

    end

    def set_expire(key)
      @exec_timestamp[key] = Time.now
      self.log "set_expire, key=#{key}, execute_time=#{@exec_timestamp[key]}"
    end

    # trueならまだ有効期限内
    def check_expire(key)
      self.log "check_expire, key=#{key}, execute_time=#{@exec_timestamp[key]}"
      return false if @exec_timestamp[key].nil?
      now = Time.now
      diff = (now - @exec_timestamp[key]).to_i.abs
      diff < @expire_time[key] ? true : false
    end

    def check_free_cupid
      self._check_cupid('free', FREE_CUPID,'無料キューピッドが引けます', '無料でお願い♪キューピッド')
    end

    def check_smile_cupid
      self._check_cupid('smile', SMILE_CUPID, 'スマイルキューピッドを引こう', '無料でお願い♪キューピッド')
    end

    def _check_cupid(cupid_name, expire_constant, news_link_text, cupid_text)
      self.log "check_#{cupid_name}_cupid start."
      return if self.check_expire expire_constant #期限内だったらやらない
      self.set_expire expire_constant
      self.click_element('#mail')
      if self.click_link(news_link_text)
        sleep 1
        self.click_link(cupid_text)
        sleep 10
        self.flash_knock
      end
      self.log "check_#{cupid_name}_cupid end."
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
      return false if self.check_expire QUEST_EMPTY #期限内だったらやらない
      self.flash_knock

      if self.click_element('#js_questBtn>a') == false
        self.log "quest button not found. quest_exec end."
        return false
      end

      # 通常時
      if self.quest_normal_check
        ret =  self.quest_normal_exec
      # おねがいハンターズ
      elsif self.quest_hunters_check
        ret = self.quest_hunters_exec
      # 聖櫻学園物語
      elsif self.quest_story_check
        ret = self.quest_story_exec
      else
        # なかったら悪xxレイドイベントと仮定して走ってみる
        ret = self.quest_raidevent_exec
      end
      self.log "quest_exec end."
      ret
    end

    # レイドイベントボス出現中なら倒す
    def _raidboss_appear_exec(func_name, click_css, click_selector, click_link_name, exec_btn_css, exec_expire_css, exist_css = nil, exist_selector = :xpath)
      self.log "#{func_name} start."
      return false if self.check_expire RAIDBOSS_EMPTY #期限内だったらやらない
      unless exist_css.nil?
        return false unless self.exist_element(exist_css, exist_selector)
      end

      result = false
      if self.click_element(click_css, click_selector)
        while self.click_link(click_link_name)
          break unless self.vs_raidboss_exec(exec_btn_css, exec_expire_css) # 救出が無理だったら諦める
          result = true
        end
      end
      self.log "#{func_name} end."
      self.move MYPAGE_URL
      result
    end

    # レイドイベントボス出現中なら倒す
    def raidboss_appear_exec
      self._raidboss_appear_exec(
        'raidboss_appear_exec',
        'p.raidBossAppear',
        :css,
        '救出する',
        'div.sprite1_battleBtn11',
        'a.btn.btnPrimary.w96.jsTouchActive.battleBtn.relative.btnDisabled'
      )
    end

    # お願いハンターズのレイドイベントボス出現中なら倒す
    def raidboss_appear_hunters_exec
      self._raidboss_appear_exec(
        'raidboss_appear_hunter_exec',
        "//img[contains(@src, 'boss_appear.png')]",
        :xpath,
        '捕まえる',
        'a.btn.btn.btnPrimary.jsTouchActive.battleBtn',
        '#js_pushCandyPower',
        "//a[contains(@href, '/raidwar/status?eventId=')]"
      )
    end

    # TODO 動作未確認
    def help_exec
      self._raidboss_appear_exec(
        'help_exec',
        "img[src='http://stat100.ameba.jp/vcard/ratio20/images/mypage/raid/alert_help.png']",
        :css,
        'お助けに行く',
        'a.btn.btn.btnPrimary.jsTouchActive.battleBtn',
        'a.btn.btn.btnPrimary.jsTouchActive.battleBtn.relative.btnDisabled',
        "img[src='http://stat100.ameba.jp/vcard/ratio20/images/mypage/raid/alert_help.png']",
        :css
      )
    end

    # なんらかのアクションに成功したらtrue
    def vs_raidboss_exec(btn_css, expire_css, max_beat = DEFAULT_MAX_BEAT)
      self.log "vs_raidboss_exec start."
      help_request = self.request_help
      battle_done = false
      beat_count = 0
      while beat_count < max_beat and self.click_element(btn_css)
        self.flash_knock
        battle_done = true
        beat_count += 1
        break if self.exist_element(expire_css)
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
      unless self.click_element("img[src='http://stat100.ameba.jp/vcard/ratio20/images/quest/btn_challenge.png']")
        self.log "Now you're in area select page. But quest btn not found!"
        return false
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
      unless self.click_element("//a[contains(@href, '/raidwar/quest/detail?eventId=')]", :xpath)
        self.log "Now you're in raid event page. But quest btn not found!"
        return false
      end
      self.run_quest('#js_btnFight', ['#js_btnFight.inlineBlock.btnFight.btnFightOff'])
      self.log "quest_hunters_exec end."
    end

    # 聖櫻学園物語
    def quest_story_check
      self.exist_element("//img[contains(@src, 'stagebtn_on_')]", :xpath) #Touchボタンがあったら
    end

    def quest_story_exec
      self.log "quest_story_exec start."
      unless self.click_element("//img[contains(@src, 'stagebtn_on_')]", :xpath)
        self.log "Now you're in quest story page. But quest btn not found!"
        return false
      end
      while true
        self.run_quest('div#js_questTouchArea.questTouchArea', [])
        if self.exist_element('#js_normalItemButton') &&
          self.click_element('#js_normalItemButton')
            self.flash_knock
            if self.exist_element("//a[contains(@href, '/story/quest?eventId=')]", :xpath)
              self.click_element("//a[contains(@href, '/story/quest?eventId=')]", :xpath)
            else
              break
            end
        # TODO 「手伝いに行く」の時にうまく遷移したい
        else
          break
        end
      end

      self.log "quest_story_exec end."
    end


    def quest_raidevent_exec
      self.log "quest_raidevent_exec start."
      self.run_quest
      self.log "quest_raidevent_exec end."
    end

    # TODO 動作未確認
    def touch_bonus_exec
      return unless self.exist_element('div#bustUpGirlBtn.btnBlueGrn')
      self.click_element('div#bustUpGirlBtn.btnBlueGrn')
      self.log "Touch start!"
      return unless self.click_element("//div[contains(@style, 'background-image: url(http://stat100.ameba.jp/vcard/ratio20/images/animation/quest/touchbonus/common_voiceAlertOffBtn.png);')]", :xpath) #Touchボタンがあったら
      self.log "voice off."
      # TODO これでは駄目。違う方法が必要
      # self.flash_knock(4)

      # クエストに戻る
      click_element('div#quest.btnGlue') if exist_element('#quest.btnGlue')
      self.log "touch End."
    end

    def run_quest(btn_id = '#btnFight',
      end_ids = ['#btnFight.relative.noneTapColor.sprite2_btnSearchOff',
                 '#btnFight.relative.noneTapColor.sprite2_btnSearchUpoff',
                 '#btnFight.sprite1_btnFightOff'])
      # 通常時
      while(self.click_element(btn_id))
        sleep 3
        # もし3秒経ってもボタンが有効になってなかったら終了
        self.touch_bonus_exec
        break if end_ids.inject(false){|is_end, e| is_end || self.exist_element(e)}

        # TODO 判定のロジックがあまり良くないので変えたい
        # TODO 通常クエスト時に上手く空判定が出来ていない
        self.set_expire QUEST_EMPTY if self.exist_element("//div[@id='outStamina' and @class='popup' and contains(@style, 'position')]", :xpath) #体力切れたらexpireセット
      end
      true
    end
  end
end
