from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import TimeoutException
import os


STARTNUM=1
ERRORNUM=0
ERRORTHRESHOLD=2
URLPREFIX="https://~-"
USERID="~@~"
USERPW="~"

mime_types = "application/pdf,application/vnd.adobe.xfdf,application/vnd.fdf,application/vnd.adobe.xdp+xml"


#http://stackoverflow.com/questions/15954682/setting-selenium-to-use-custom-profile-but-it-keeps-opening-with-default/23330140#23330140
fp = webdriver.FirefoxProfile()
fp.set_preference("browser.download.folderList", 2) # custom location
fp.set_preference("browser.download.manager.showWhenStarting", False)
fp.set_preference("browser.download.dir", os.getcwd())

#http://selenium-python.readthedocs.io/faq.html#how-to-auto-save-files-using-custom-firefox-profile
fp.set_preference("browser.helperApps.neverAsk.saveToDisk", mime_types)
fp.set_preference("plugin.disable_full_page_plugin_for_types", mime_types)
fp.set_preference("pdfjs.disabled", True)
fp.set_preference('permissions.default.stylesheet', 2)

##fp.set_preference('permissions.default.image', 2)
fp.add_extension(os.getcwd()+"\quickjava-2.0.6-fx.xpi")
fp.set_preference("thatoneguydotnet.QuickJava.curVersion", "2.0.6.1") ## Prevents loading the 'thank you for installing screen'
fp.set_preference("thatoneguydotnet.QuickJava.startupStatus.Images", 2)  ## Turns images off
fp.set_preference("thatoneguydotnet.QuickJava.startupStatus.AnimatedImage", 2)  ## Turns animated images off
fp.set_preference('dom.ipc.plugins.enabled.libflashplayer.so', 'false')

#Driver Start
driver = webdriver.Firefox(firefox_profile=fp)
driver.get(URLPREFIX+str(STARTNUM).rjust(6,'0'))

#ID and PW then Submit
driver.find_element_by_xpath("//*[@id='kc-login-email']").send_keys(USERID)
driver.find_element_by_xpath("//*[@id='kc-login-password']").send_keys(USERPW)
driver.find_element_by_xpath("//*[@id='login-form']/div[3]/div/button").click()

while True:
    STARTNUM=STARTNUM+1
    try:
        #Check if the pdf link exists
        WebDriverWait(driver, 20).until(EC.element_to_be_clickable((By.XPATH, "/html/body/div[1]/div/div[1]/div[1]/div/div[2]/button/a")))
        python_link = driver.find_element_by_xpath("/html/body/div[1]/div/div[1]/div[1]/div/div[2]/button/a")
        #driver.get(python_link.get_attribute("href"))
        driver.execute_script("window.open('"+python_link.get_attribute("href")+"', 'new_window')")
    except (NoSuchElementException, TimeoutException):
        ERRORNUM=ERRORNUM+1
		print "except="+str(ERRORNUM)
        if driver.title=="Access Denied":
            pass
        elif driver.title=="Page cannot be found":
            print ">Page cannot be found"
            if ERRORNUM==2:
                return
            else:
                pass
        else:
            print ">unknown error!"
            return 

    ERRORNUM=0
    print URLPREFIX+str(STARTNUM).rjust(6,'0')
    driver.get(URLPREFIX+str(STARTNUM).rjust(6,'0'))