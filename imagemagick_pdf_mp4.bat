
convert -density 400 api.pdf pic-%%03d.png
rem https://www.everythingcli.org/convert-pdf-to-mp4/
rem http://superuser.com/questions/881399/can-imagemagick-number-output-files-with-two-digits
rem http://superuser.com/questions/756323/pdf-to-video-conversion
rem http://stackoverflow.com/questions/1327431/how-do-i-escape-ampersands-in-batch-files

@echo off
setlocal enabledelayedexpansion
rem http://stackoverflow.com/questions/12518242/batch-script-for-loop-wont-set-variable
rem http://snoopybox.co.kr/1404

set /a count=0

for %%i in (pic-*.png) do ( 
rem https://www.experts-exchange.com/questions/26558163/Copy-even-or-odd-files.html
rem http://www.dostips.com/forum/viewtopic.php?t=4227&start=15
  set filename=%%~ni
  set /a number=1000!filename:~-3! %% 1000 %% 2

  rem http://stackoverflow.com/questions/10077866/numeric-error-in-batch
  rem http://egloos.zum.com/timecandy/v/4041323
  rem http://stackoverflow.com/questions/3432851/dos-bat-file-equivalent-to-unix-basename-command
  
  set formattedValue=000!count!
  rem http://stackoverflow.com/questions/9430642/win-bat-file-how-to-add-leading-zeros-to-a-variable-in-a-for-loop  
  
  if !number! equ 0 ( 
    set exec=convert %%i
  ) else ( 
    
    set exec=!exec! %%i +append out_!formattedValue:~-3!.png
	echo !exec!
	!exec!
	rem http://apple.stackexchange.com/questions/52879/how-to-combine-two-images-into-one-on-a-mac
	
	set /a count=!count!+1
  )
)

if %number% equ 0 (
  set exec=identify -format "%%[fx:w]x%%[fx:h]" out_000.png
  rem http://stackoverflow.com/questions/889518/windows-batch-files-how-to-set-a-variable-with-the-result-of-a-command
  rem http://stackoverflow.com/questions/1555509/can-imagemagick-return-the-image-size
  echo %exec%

  FOR /F "delims=" %%i IN ('%exec%') DO set size=%%i
  set formattedValue=000%count%
  set exec=convert %filename%.png -gravity west -background white -extent %size% out_%formattedValue:~-3%.png
  rem http://stackoverflow.com/questions/1787356/use-imagemagick-to-place-an-image-inside-a-larger-canvas
  echo !exec!
  !exec!
)


ffmpeg -r 1/5 -i out_%%03d.png -c:v libx264 -r 10 -vf scale=1280:-2 -crf 18 -preset veryfast -pix_fmt yuv420p out.mp4
rem http://stackoverflow.com/questions/20847674/ffmpeg-libx264-height-not-divisible-by-2
rem http://superuser.com/questions/486325/lossless-universal-video-format
rem http://superuser.com/questions/533695/how-can-i-convert-a-series-of-png-images-to-a-video-for-youtube



rem http://hamelot.io/visualization/using-ffmpeg-to-convert-a-set-of-images-into-a-video/
rem http://trac.ffmpeg.org/wiki/Slideshow

endlocal
