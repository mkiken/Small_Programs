#ruby:"mae_run.rb"

require 'selenium-webdriver'
require './mae'
require 'yaml'
include Mae

# Chrome driver
def get_chrome_driver
  switches = []
  switches << '--user-agent=Mozilla/5.0 (iPad; CPU OS 8_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B410 Safari/600.1.4'
  switches << '--app-window-size=512,384 '

  # http://qiita.com/yooo_gooo/items/50e66aa2624f521183a2
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.timeout = 120

  driver = Selenium::WebDriver.for :chrome, :switches => switches, :http_client => client
# ドライバー共通のタイムアウト設定
  driver.manage.timeouts.implicit_wait = 5 # seconds
  driver

end

def main
  config        = YAML.load_file('./config.yml')
  gree_id       = config['gree_id']
  gree_password = config['gree_password']
  quest_type    = config['quest_type']
  max_count     = config['max_count']
  exec(gree_id, gree_password, quest_type, max_count, 1)
end

def exec(gree_id, gree_password, quest_type, max_count, count)
  return false if count >= max_count


  begin
    driver        = get_chrome_driver
    mae           = Mae::Mae.new
    extend_logging mae
    mae.log "#{count}th game start."
    mae.setting(driver, gree_id, gree_password, 10000000, quest_type)
    mae.play
  rescue => ex
    p ex

    # driver.closeに失敗することがあるので、念のためbeginで囲っておく
    begin
      # 終了時にドライバーを閉じる
      driver.close
    rescue => e
      p e
    end
    # ドライバーが閉じるように一応30秒待つ
    sleep 30
    exec(gree_id, gree_password, quest_type, max_count, count + 1)
  end
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
