# foto-gallery

This is a flutter based web interface that connects to an existing pigallery2 server to show folders/photos/videos in a mobile friendly format.
This is just for testing purposes at this point, and please leave any feedback under issues/discussions in github.

pigallery2 server does not work well with CORS, hence you need to create a new nginx web server in the same domain as your running pigallery2 server.

Eg:
- If my pigallery2 is running at http://myhomeserver.local:8045/ then my Foto server will run at http://myhomeserver.local:8089/foto/
- CORS will work if both servers run on the same domain name, but any port number is fine.

## Instructions
1. Create a new nginx web server, that proxies to your pigallery2 server. Sample nginx.conf file [here](sampleconfig/nginx.conf). It proxies all requests except the location /foto/.
2. Deploy the nginx instance in docker or standalone, depending on your setup.
3. Download foto.zip from the release section in github on this page, unzip it into <nginx-root-dir>/foto.
4. Edit foto/assets/foto_settings.json and set the user and password for your pigallery2 instance. Sample [here](sampleconfig/foto_settings.json).
5. Start nginx and point to http://nginx-host:nginx:port/foto/
