FROM nginx:stable-alpine AS runner

COPY resources/nginx.conf /etc/nginx/conf.d/default.conf
# COPY package.json /usr/share/nginx/html
COPY  build/web /usr/share/nginx/html/foto

# Copy the EntryPoint
COPY resources/entryPoint.sh /
RUN chmod +x /entryPoint.sh

ENTRYPOINT ["/entryPoint.sh"]

CMD ["nginx", "-g", "daemon off;"]