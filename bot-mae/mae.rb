# coding: utf-8

require 'date'
# ミリオンアーサー エクスタシス オートパイロット for Selenium + WebDriver
module Mae

  class Mae

    GAME_TOP_URL         = 'http://x-arthur.gree-pf.net/?use_iframe=false'
    SNS_HOME_URL         = 'https://id.gree.net/login/entry?ignore_sso=1&backto='
    QUEST_EMPTY          = 1
    RAID_EMPTY           = 2
    HELLO_EMPTY          = 3
    QUEST_TYPE_NORMAL    = 1
    QUEST_TYPE_DAILY     = 2
    QUEST_TYPE_SANCTUARY = 3

    # コンストラクタ
    def initialize
      # メインループの最大回転数（処理の回数）
      @main_loop_max = 10000000
      @expire_time = {
        QUEST_EMPTY => 150 * 60, # APが空になったらクエストをやらない時間
        RAID_EMPTY  => 15 * 60,  # BCが空になったらレイド討伐をやらない時間
        HELLO_EMPTY => 15 * 60   # 1回やったら挨拶をやらない時間
      }.freeze
      @exec_timestamp = {
        QUEST_EMPTY => nil,
        RAID_EMPTY  => nil,
        HELLO_EMPTY  => nil
      }
      @const_to_str = {
        QUEST_EMPTY => 'QUEST_EMPTY',
        RAID_EMPTY  => 'RAID_EMPTY',
        HELLO_EMPTY => 'HELLO_EMPTY'
      }
      @parameter_list = {
        'QUEST_EXEC_COUNT' => 1, # 1回の行動でクエストを行う回数
        'RAID_EXEC_COUNT'  => 5  # 1回の行動でレイドを殴る回数
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

    def setting(driver, id, pass, max_count, quest_type, is_mobage)
      # Selenium WebDriver をセットする（必須）
      @driver = driver
      # SNS の ID をセット。
      @id = id
      # SNS の password をセット。
      @pass = pass
      # メインループの最大回転数を変更する
      @main_loop_max = max_count
      # 征域優先か
      @quest_type = quest_type
      # MOBAGE版か
      @is_mobage = is_mobage
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

    # 動かない
    def touch_element(target_css, selector=:css)
      @driver.extend Selenium::WebDriver::DriverExtensions::HasTouchScreen

      begin
        target_btn = self.find_element(target_css, selector)
        @driver.touch.single_tap(target_btn).perform
      rescue Exception => ex
        puts ex.message
        self.log "touch fail. invalid target => " + target_css
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
    def flash_knock(target='#canvas', count=1)
      begin
        current_url = @driver.current_url
        canvas = self.find_element(target)
        if canvas
          cnt = 0 # 無限ループ対策
          while current_url == @driver.current_url and cnt <= 10 do
            count.times{
              canvas.click
              # self.touch_element(target)
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
      raid_result = self.raid_exec(@parameter_list['RAID_EXEC_COUNT'])
      result |= raid_result

      sleep 3
      self.go_mypage

      # アセロラの材料
      result |= self.get_acerola_material
      sleep 1
      self.go_mypage

      # レイド未受け取り報酬
      result |= self.receive_not_received_raid_reward
      sleep 1
      self.go_mypage

      # 未受け取りギフトがあったら受け取る
      result |= self.receive_gift
      sleep 1
      self.go_mypage

      # 挨拶をする
      result |= self.hello_exec
      sleep 1
      self.go_mypage

      # レイドを叩けていなかったら探索
      result |= self.quest_exec(@parameter_list['QUEST_EXEC_COUNT']) unless raid_result
    end

    def quest_exec(limit)
      return false if check_expire(QUEST_EMPTY)

      result = self.click_element('a.btn-quest-inner')
      if @quest_type == QUEST_TYPE_SANCTUARY
        tab_list = self.find_elements('a.tab-child-inner')
        tab_list[1].click
        result &= true
      elsif @quest_type == QUEST_TYPE_DAILY
        # 曜日クエストに行く
        result &= self.click_element('a.tab-child-inner')
      elsif @quest_type == QUEST_TYPE_NORMAL
        result &= true
      else
        raise "不明なQUEST_TYPE => #{@quest_type}"
      end

      if result
        # アセロライベントがあったら
        # if self.click_link('材料をGET!する！')
          # self.flash_knock('div#reel', 5)
          # return true
        # end
        limit.times{
          if @quest_type == QUEST_TYPE_SANCTUARY
            # result |= self.click_element('a.display-block > div.quest-hegemony-stage-area.margin-auto-t10')
            # result |= self.click_element("a[href*='quest_exec']")
            result |= self.click_element("a[href*='quest_exec'].display-block")
          elsif @quest_type == QUEST_TYPE_DAILY
            result |= self.click_element('div.quest-stage-list.margin-auto-t10')
          elsif @quest_type == QUEST_TYPE_NORMAL
            result |= self.click_element('div.quest-stage-area.margin-auto-t10')
          end
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
      self.remove_expire(RAID_EMPTY) if result
      result
    end

    def raid_exec(limit)
      # return false if self.check_expire(RAID_EMPTY)
      count = 0
      while count < limit && (self.help_raidboss_exec || self.own_raidboss_exec)
        count += 1
      end
      count > 0
    end

    def help_raidboss_exec
      return false unless self.click_element('div.btn-raid-rescue')
      sleep 1
      # 未救援レイド
      new_raid_help_button = self.click_element('div.btn-wrap-grad-gold.width-100 > a.btn-inner.font-size-normal.bg-grad-red')
      unless new_raid_help_button
        sleep 1
        # 救援済みレイド
        raid_help_button = self.click_element('div.btn-wrap-grad-gold.width-100 > a.btn-inner.font-size-normal')
        unless raid_help_button
          return false
        end
      end
      # 救援のレイドイベント時は超弱攻撃優先
      return vs_raidboss_exec(true)
    end

    def own_raidboss_exec
      return false unless self.click_element('div.btn-raid-appear')
      # 救援を出せたら出す
      return true if self.click_element('div.blink-object')
      vs_raidboss_exec
    end

    # レイドボスとの戦闘を行う
    #
    # @param [bool] is_weak_first 超弱攻撃優先で使う場合true
    # @return [bool]
    def vs_raidboss_exec(is_weak_first = false)
      result = self.click_element('div.box-child > a.btn-attack-0')
      result |= self.click_element('div.box-child.padding-r10 > a.btn-attack-20')
      # レイドイベント用
      if is_weak_first then
        # 0BC
        result |= self.click_element('div.box-child > a.btn-attack-coop-weak-0')
        result |= self.click_element('div.box-child > a.btn-attack-coop-0')
        # 20BC
        result |= self.click_element('div.box-child > a.btn-attack-coop-weak-20')
        result |= self.click_element('div.box-child > a.btn-attack-coop-20')
      else
        # 0BC
        result |= self.click_element('div.box-child > a.btn-attack-coop-0')
        result |= self.click_element('div.box-child > a.btn-attack-coop-weak-0')
        # 20BC
        result |= self.click_element('div.box-child > a.btn-attack-coop-20')
        result |= self.click_element('div.box-child > a.btn-attack-coop-weak-20')
      end
      self.set_expire(RAID_EMPTY) unless result
      return result
    end

    def receive_not_received_raid_reward
      # 新着情報をみる
      self.click_element('a.js-news-popup-open.btn-information-inner')
      return false unless self.click_link("未受取レイド報酬があります")
    end

    def receive_gift
      # 新着情報をみる
      self.click_element('a.js-news-popup-open.btn-information-inner')
      sleep 1
      # return false unless self.click_element("//a[contains(@href, 'present')]", :xpath)
      return false unless self.click_element("//a[contains(text(), '件届いています')]", :xpath)
      sleep 1
      result = self.click_link("一括受け取り")
      sleep 2
      result
    end

    # アセロラ材料
    def get_acerola_material
      if @is_mobage
        # TODO mobage版だと動かない
        # self.flash_knock('div#gamecanvas', 5)
        # self.flash_knock('div#qp_', 5)
        # self.flash_knock('canvas#qo_33', 5)
        return false
      end
      # 新着情報をみる
      self.click_element('a.js-news-popup-open.btn-information-inner')
      sleep 1
      # return false unless self.click_element("//a[contains(@href, 'present')]", :xpath)
      return false unless self.click_element("//a[contains(text(), '個GETできます')]", :xpath)
      sleep 1

      self.flash_knock('div#reel', 5)

      return true
    end


    # 挨拶をする
    def hello_exec
      return false if self.check_expire(HELLO_EMPTY)
      return false unless self.click_element('div.btn-gacha')
      sleep 1
      result = self.click_link("祝福する")
      sleep 2
      self.set_expire(HELLO_EMPTY) if result
      result
    end

  end #class
end #module
