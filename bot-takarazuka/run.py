# ライブラリ読み込み
from selenium import webdriver
import time

# クロームの立ち上げ
driver = webdriver.Chrome()

# ページ接続
driver.get('https://www.takarazuka-ticket.com/mp/twjlg.do?md=1&ls=2&ul=https://www.takarazuka-ticket.com/rt/twjkl.do')

# ログインする

# 決定ボタンのクリック
# driver.find_element_by_xpath('//*[@id="editAccountForm"]/p[2]').click()

# 2時間終了を待つ
time.sleep(7200)

# クロームの終了処理
driver.close()
