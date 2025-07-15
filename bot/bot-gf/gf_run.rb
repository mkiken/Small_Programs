#ruby:"gf_run.rb"

require 'selenium-webdriver'
require './gf'
include GF

# Chrome driver
def get_chrome_driver
  switches = []
  switches << '--user-agent=Mozilla/5.0 (iPhone; CPU iPhone OS 7_0 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/7.0 Mobile/11A465 Safari/9537.53 '
  switches << '--app-window-size=1024,768 '
  # タイムアウト設定
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.timeout = 30
  driver = Selenium::WebDriver.for :chrome, :switches => switches, :http_client => client
  # ドライバー共通のタイムアウト設定
  driver.manage.timeouts.implicit_wait = 2 # seconds
  driver
end

driver = get_chrome_driver
ameba_id = 'YOUR_ID'
ameba_password = 'YOUR_PASSWORD'
gf = GF::GF.new
gf.setting(driver, ameba_id, ameba_password, 10000000)
gf.play

# 終了時にドライバーを閉じる
driver.close
