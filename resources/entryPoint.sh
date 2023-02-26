#!/bin/sh


sed -i "s,PIGALLERY2_BASEURL_PROP,$PIGALLERY2_BASEURL_PROP,g" /etc/nginx/conf.d/default.conf
sed -i "s/PIGALLERY2_LOGIN_PROP/$PIGALLERY2_LOGIN_PROP/g" /usr/share/nginx/html/foto/assets/foto_settings.json
sed -i "s/PIGALLERY2_PASSWORD_PROP/$PIGALLERY2_PASSWORD_PROP/g" /usr/share/nginx/html/foto/assets/foto_settings.json

exec "$@"