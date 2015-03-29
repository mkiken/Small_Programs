#ruby:"mae_run.rb"

require 'selenium-webdriver'
require './mae'
include Mae

# Chrome driver
def get_chrome_driver
  switches = []
  switches << '--user-agent=Mozilla/5.0 (iPad; CPU OS 8_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B410 Safari/600.1.4'
  switches << '--app-window-size=512,384 '

  driver = Selenium::WebDriver.for :chrome, :switches => switches
  # ドライバー共通のタイムアウト設定
  driver.manage.timeouts.implicit_wait = 5 # seconds
  driver

end

def main
  driver       = get_chrome_driver
  gree_id       = 'YOUR_GREE_ID'
  gree_password = 'YOUR_GREE_PASSWORD'
  mae       = Mae::Mae.new
  extend_logging mae
  mae.setting(driver, gree_id, gree_password, 10000000)
  mae.play

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
