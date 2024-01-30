#!/bin/bash

# Determines if SSL configured by the end user or not.

# Checks if SSL certificate and key exists, otherwise default to http traffic
if [ -f "${SSL_CERT}" ] && [ -f "${SSL_CERT_KEY}" ]; then
    envsubst '${SSL_CERT},${SSL_CERT_KEY}' \
    < /etc/nginx/templates/https.conf > /var/lib/www-user/panel.conf
else
    echo "[setup] Warning: SSL Certificate was not specified or doesnt exist, using HTTP."
    cat /etc/nginx/templates/http.conf > /var/lib/www-user/panel.conf
fi
