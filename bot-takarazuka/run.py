# ライブラリ読み込み
import json
import time

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

# クロームの立ち上げ
driver = webdriver.Chrome()
wait = WebDriverWait(driver, 15)

# ページ接続
driver.get(
    'https://www.takarazuka-ticket.com/mp/twjlg.do?md=1&ls=2&ul=https://www.takarazuka-ticket.com/rt/twjkl.do')

# ログインする

# ログインフォーム
login_id_form = wait.until(EC.element_to_be_clickable((By.ID, 'loginid_form')))

with open('credential.json') as f:
    d = json.load(f)

login_id_form.send_keys(d['id'])
driver.find_element(By.ID, 'password_form').send_keys(d['password'])

login_button = wait.until(EC.element_to_be_clickable((By.ID, 'login_btn')))
login_button.click()

while True:
    time.sleep(3)
    if driver.title == "Sorry Page" or "ただいまアクセスが集中し、つながりにくい状態です。" in driver.find_element(
            "body > section.main > section.unit.unit_warning > p.fc_red").text == "":
        driver.refresh()

# 2時間終了を待つ
# time.sleep(7200)

# クロームの終了処理
# driver.close()
