# foto-gallery

This is a flutter based web interface that connects to an existing pigallery2 server to show folders/photos/videos in a mobile friendly format.
This is just for testing purposes at this point, and please leave any feedback under issues/discussions in github.
pigallery2 server does not work well with CORS, hence you need to create a new nginx web server in the same domain as your running pigallery2 server.

To simplify all this, I have a docker image available that takes 3 properties as environment variables - PiGallery2 URL, username, password - and deploys everything automatically in a container.

Try it and please send me feedback.

https://user-images.githubusercontent.com/68288615/218384061-7f8e865d-8d80-4763-8a65-5aa039444c53.mp4

## Instructions
1. Create a docker instance and run it!
2. Sample Docker compose file is [here](sampleconfig/docker-compose.yml), its self-explanatory - takes 3 properties as environment variables.
3. Only PIGALLERY2_BASEURL_PROP is mandatory, PIGALLERY2_LOGIN_PROP and PIGALLERY2_PASSWORD_PROP are optional and do not need to specify if you are running pigallery2 without login auth.
4. Start the docker instance and point to http://host:post/foto/  -  /foto/ is mandatory in the URL and hardcoded (for now).
