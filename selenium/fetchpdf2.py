from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import TimeoutException

MYURL="~~~"

# +file/unknown 
mime_types = "application/pdf,application/vnd.adobe.xfdf,application/vnd.fdf,application/vnd.adobe.xdp+xml,file/unknown"

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
driver.get(MYURL)

# Extract URLs from the list
links=driver.find_element_by_xpath("/html/body/table/tbody/tr[3]/td/table/tbody/tr/td[3]/table/tbody/tr[3]/td/table[2]/tbody").find_elements_by_tag_name("a")
urllist=[]

for link in links:
    urllist.append(link.get_attribute("href"))

for aurl in urllist:
    driver.get(aurl)
    afiles=driver.find_element_by_xpath("/html/body/table/tbody/tr[3]/td/table/tbody/tr/td[3]/table/tbody/tr[3]/td/table/tbody").find_elements_by_tag_name("a")
    driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")

    for afile in afiles:
        driver.get(afile.get_attribute("href"))
        driver.implicitly_wait(5)
