#ruby:"d_prov_run.rb"

require 'selenium-webdriver'
require './d_prov'
include D_prov

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

driver       = get_chrome_driver
dmm_id       = 'YOUR_DMM_ID'
dmm_password = 'YOUR_DMM_PASS'
d_prov       = D_prov::D_prov.new
d_prov.setting(driver, dmm_id, dmm_password, 10000000)
d_prov.play

# 終了時にドライバーを閉じる
driver.close
