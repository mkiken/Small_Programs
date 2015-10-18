# coding: utf-8

require 'date'
require_relative '../mae'
# ミリオンアーサー エクスタシス オートパイロット for Selenium + WebDriver
module Mae_mobage

  class Mae_mobage < Mae::Mae

    GAME_TOP_URL         = 'http://g12023264.sp.pf.mbga.jp/'
    SNS_HOME_URL         = 'http://g12023264.sp.pf.mbga.jp/'

    # SNSにログイン
    def login_sns
      self.log 'login_sns OK'
      @driver.get SNS_HOME_URL

      self.input_text('subject_id', @id)
      self.input_text('subject_password', @pass)

      puts "please input image pass."
      # 画像認証を待つ
      while str = STDIN.gets
        break if str.chomp == "ok"
        print "if you are ready, enter 'ok'"
        sleep 5
      end

      unless self.click_element('button#login')
        self.log 'login_sns abort'
        @driver.close
      end
    end

    def go_mypage
      self.move GAME_TOP_URL
      unless self.click_element('.btn-mypage')
        self.log('go to mypage fail.')
        @driver.close
      end
    end


  end #class
end #module
