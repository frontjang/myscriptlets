import re
import os
import time

from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC

mime_types = "file/unknown,application/x-ica"

fp = webdriver.FirefoxProfile()
fp.set_preference("browser.download.folderList", 2)
fp.set_preference("browser.download.manager.showWhenStarting", False)
fp.set_preference("browser.download.dir", "c:\local_data")
fp.set_preference("browser.helperApps.neverAsk.saveToDisk", mime_types)
fp.set_preference("plugin.disable_full_page_plugin_for_types", mime_types)




DOMAIN="http://"
USER=""
PASSWORD=""


driver = webdriver.Firefox(firefox_profile=fp)
driver.get(DOMAIN)

waitElement = WebDriverWait(driver, 10).until(
  EC.presence_of_element_located((By.ID, "password"))
)

input_id=driver.find_element_by_id('user')
input_id.send_keys(USER)
input_id=driver.find_element_by_id('password')
input_id.send_keys(PASSWORD)
input_id.send_keys(Keys.ENTER)

waitElement = WebDriverWait(driver, 2).until(
  EC.presence_of_element_located((By.ID, "connect_btn_box"))
)
startButton=driver.find_element_by_id('connect_btn_box')
startButton=startButton.find_elements_by_tag_name('a')
startButton[0].click()
driver.get(startButton[0].get_attribute('href'))

waitElement = WebDriverWait(driver, 2).until(
  EC.presence_of_element_located((By.TAG_NAME, "script"))
)
scripts=driver.find_elements_by_tag_name('script')
rawScript=scripts[2].get_attribute('innerHTML')
url=re.search("/Citrix/.+'",rawScript).group()[:-1]
driver.get(DOMAIN+url)

"""
waitElement = WebDriverWait(driver, 2).until(
  EC.presence_of_element_located((By.TAG_NAME, "body"))
)
embedElement=driver.find_elements_by_tag_name('embed')[0]
src=embedElement.get_attribute('src')
driver.get(src)
"""

theFile='C:\\local_data\\launch.ica'
os.startfile(theFile)

time.sleep(5)
os.remove(theFile)
driver.close()
