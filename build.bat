rem call flutter build web --profile --source-maps --base-href "/foto/"
call flutter build web --release --base-href "/foto/"
call del .\build\web.zip
call Powershell.exe Compress-Archive build\web\* build\web.zip
call Powershell.exe Expand-Archive -Force build\web.zip Z:\myweb\html\foto\
call copy Z:\myweb\html\foto\assets\foto_settings_stg.json Z:\myweb\html\foto\assets\foto_settings.json 

rem OTHER CMDS FOR DOCKER
rem sudo docker build -t varieum/foto-gallery .
rem sudo docker run -it -e PIGALLERY2_BASEURL_PROP="http://192.168.1.78:8086" -e PIGALLERY2_LOGIN_PROP=test -e PIGALLERY2_PASSWORD_PROP=testpwd -p 8003:80 varieum/foto-gallery
rem sudo docker login
rem sudo docker push varieum/foto-gallery
