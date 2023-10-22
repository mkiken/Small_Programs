# ライブラリ読み込み
import datetime
import json
import time

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait


def is_access_failed(driver) -> bool:
    if driver.title == "Sorry Page":
        return True

    elements = driver.find_elements(By.CLASS_NAME, "fc_red")

    if len(elements) > 0 and "ただいまアクセスが集中し、つながりにくい状態です。" in elements[0].text:
        return True

    return False

# アクセスが失敗してたらreloadしなおす
def reload_until_load_success(driver) -> bool:
    count = 0
    while True:
        count += 1
        time.sleep(5)
        now = datetime.datetime.now()
        if is_access_failed(driver):
            print("reload %d: %s", count, now)
            driver.refresh()
        else:
            break

# クロームの立ち上げ
driver = webdriver.Chrome()
wait = WebDriverWait(driver, 15)

# 宝塚友の会 先行販売
# ページ接続
driver.get(
    'https://www2.takarazuka-ticket.com/st/twjkl.do')

reload_until_load_success(driver)

print("attempt to login.")
# ログインフォーム
login_id_form = wait.until(EC.element_to_be_clickable((By.ID, 'loginid_form')))

with open('credential.json') as f:
    d = json.load(f)

login_id_form.send_keys(d['id'])
driver.find_element(By.ID, 'password_form').send_keys(d['password'])

login_button = wait.until(EC.element_to_be_clickable((By.ID, 'login_btn')))
login_button.click()
print("login button clicked. load...")

reload_until_load_success(driver)

print("load success! wait 7200 sec.")

# 2時間終了を待つ
time.sleep(7200)

# クロームの終了処理
driver.close()
