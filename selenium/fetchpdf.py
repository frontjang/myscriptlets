from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import TimeoutException

STARTNUM=1
ERRORNUM=1
ERRORTHRESHOLD=2
URLPREFIX="https://~~~~~~"
USERID="~~~~~~"
USERPW="~~~~~~"


mime_types = "application/pdf,application/vnd.adobe.xfdf,application/vnd.fdf,application/vnd.adobe.xdp+xml"

fp = webdriver.FirefoxProfile()
fp.set_preference("browser.download.folderList", 2)
fp.set_preference("browser.download.manager.showWhenStarting", False)
fp.set_preference("browser.download.dir", "c:\local_data")
fp.set_preference("browser.helperApps.neverAsk.saveToDisk", mime_types)
fp.set_preference("plugin.disable_full_page_plugin_for_types", mime_types)
fp.set_preference("pdfjs.disabled", True)
fp.set_preference('permissions.default.stylesheet', 2)

##fp.set_preference('permissions.default.image', 2)
fp.add_extension("c:\local_data\quickjava-2.0.6-fx.xpi")
fp.set_preference("thatoneguydotnet.QuickJava.curVersion", "2.0.6.1") ## Prevents loading the 'thank you for installing screen'
fp.set_preference("thatoneguydotnet.QuickJava.startupStatus.Images", 2)  ## Turns images off
fp.set_preference("thatoneguydotnet.QuickJava.startupStatus.AnimatedImage", 2)  ## Turns animated images off
fp.set_preference('dom.ipc.plugins.enabled.libflashplayer.so', 'false')

#Driver Start
driver = webdriver.Firefox(firefox_profile=fp)
driver.get(URLPREFIX+str(STARTNUM).rjust(6,'0'))

#ID and PW then Submit
driver.find_element_by_xpath("/html/body/div[4]/div[2]/div[1]/div/form/div[1]/input").send_keys(USERID)
driver.find_element_by_xpath("/html/body/div[4]/div[2]/div[1]/div/form/div[2]/input").send_keys(USERPW)
driver.find_element_by_xpath("/html/body/div[4]/div[2]/div[1]/div/form/div[3]/div/button").click()

while True:
    try:
        #Check if the pdf link exists
        WebDriverWait(driver, 20).until(EC.presence_of_element_located((By.XPATH, "/html/body/div[3]/div/div/div[2]/div/div[2]/a")))

        python_link = driver.find_element_by_xpath("/html/body/div[3]/div/div/div[2]/div/div[2]/a")
        driver.get(python_link.get_attribute("href"))

        STARTNUM=STARTNUM+1
        ERRORNUM=0

    except (NoSuchElementException, TimeoutException):
        if driver.title=="Access Denied":
            STARTNUM=STARTNUM+1
            pass
        elif driver.title=="Page cannot be found":
            if ERRORNUM==2:
                break
            else:
                STARTNUM=STARTNUM+1
                ERRORNUM=ERRORNUM+1
                pass
        else:
            break

    driver.get(URLPREFIX+str(STARTNUM).rjust(6,'0'))
