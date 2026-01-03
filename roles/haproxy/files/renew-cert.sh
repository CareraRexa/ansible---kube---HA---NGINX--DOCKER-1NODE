#!/bin/bash
certbot renew --quiet --pre-hook "systemctl stop haproxy" --post-hook "systemctl start haproxy"
cat /etc/letsencrypt/live/myreactapp.duckdns.org/fullchain.pem \
    /etc/letsencrypt/live/myreactapp.duckdns.org/privkey.pem \
    > /etc/ssl/private/haproxy-ssl.pem
chmod 600 /etc/ssl/private/haproxy-ssl.pem
systemctl reload haproxy
