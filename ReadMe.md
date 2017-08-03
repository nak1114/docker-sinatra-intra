# Environment

RACK_ENV    developmant
DB_HOST     127.0.0.1
DB_USERNAME your database account
DB_PASSWORD your database password
DL_SITE     your synology url ex.http://192.168.0.1:5000
DL_USERNAME your synology account
DL_PASSWORD your synology pass word
TR_USERNAME your account
TR_PASSWORD your password

# install

```
./bin/start.sh 0.0.4
```

# nginx.conf

```
    location /websocket {
      if ($maintenance = true) {
          return 503;
      }
      proxy_pass  http://webapi1:3000;
      proxy_http_version 1.1;
      proxy_set_header Upgrade websocket;
      proxy_set_header Connection Upgrade;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   }
```
