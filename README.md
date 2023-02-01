# foto-gallery

This is a flutter based web interface that connects to an existing pigallery2 server to show folders/photos/videos in a mobile friendly format.
This is just for testing purposes at this point, and please leave any feedback under issues/discussions in github.

pigallery2 server does not work well with CORS, hence you need to create a new nginx web server in the same domain as your running pigallery2 server.

## Instructions
1. Create a new nginx web server, that proxies to your pigallery2 server. Sample nginx.conf file here
2. Deploy the nginx instance in docker or standalone, depending on your setup.
3. Download foto.zip from the release section in github on this page, unzip it into <nginx-root-dir>/foto.
4. Edit foto/assets/foto_settings.json and set the url, user and password for your pigallery2 instance. Sample here.
5. Start nginx and point to http://nginx-host:nginx:port/foto/
