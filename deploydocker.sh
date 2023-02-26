sudo pwd
git pull
flutter build web --release --base-href "/foto/"
sudo docker build -t varieum/foto-gallery .
sudo docker push varieum/foto-gallery