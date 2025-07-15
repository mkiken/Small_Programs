#ruby:"p_connect_run.rb"

require 'selenium-webdriver'
require './p_connect'
include P_connect

# Chrome driver
def get_chrome_driver
  switches = []
  # switches << 'Mozilla/5.0 (iPhone; CPU iPhone OS 8_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B410 Safari/600.1.4 '
  # switches << 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.57 Safari/537.36'
  # switches << '--app-window-size=1024,768 '
  # タイムアウト設定
  client         = Selenium::WebDriver::Remote::Http::Default.new
  client.timeout = 30
  driver         = Selenium::WebDriver.for :chrome, :switches => switches, :http_client => client
  # ドライバー共通のタイムアウト設定
  driver.manage.timeouts.implicit_wait = 5 # seconds
  driver
end

def main
  driver       = get_chrome_driver
  ameba_id       = 'YOUR_AMEBA_ID'
  ameba_password = 'YOUR_AMEBA_PASSWORD'
  p_connect       = P_connect::P_connect.new
  extend_logging p_connect
  p_connect.setting(driver, ameba_id, ameba_password, 10000000)
  p_connect.play

  # 終了時にドライバーを閉じる
  driver.close
end

# http://ksmakoto.hatenadiary.com/entry/2013/09/25/221810
# hook for log
def extend_logging obj
  mod = Module.new

  # このメソッドはhookしない
  reject_name_list = [
    'log',
    'move',
    'input_text',
    'exist_element',
    'click_element',
    'click_link',
    'set_expire',
    'remove_expire',
    'check_expire',
    'flash_knock',
    'log',
    'find_element',
    'find_elements',
  ]

  obj.methods.each {|name|
    name = name.to_s
    next if reject_name_list.include?(name) or /\A__[^_]*__\z/.match name
    mod.__send__(:define_method, name){|*args, &c|
      begin
        p "  #{Time.now.strftime('[%Y-%m-%d %H:%M:%S]')}: #{name.inspect} BEGIN"
        result = super *args, &c
      ensure
        p "  #{Time.now.strftime('[%Y-%m-%d %H:%M:%S]')}: #{name.inspect} END. result = #{result}"
      end
    }
  }

  obj.extend mod
end

main
