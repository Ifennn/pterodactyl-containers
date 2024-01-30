FROM --platform=$TARGETOS/$TARGETARCH docker.io/library/almalinux:9-minimal as base

LABEL maintainer="Cameron Carney <ccarney@zyphi.co>"

# Allows the end user to customize what php modules and packages they want on buildtime
ENV PHP_VERSION=8.3
ENV PHP_MODULES=bcmath,cli,common,fpm,gd,gmp,intl,json,mbstring,mysqlnd,opcache,pdo,pecl-zip,process,soap,sodium,xml,zstd
ENV EXTRA_PACKAGES="nmap-ncat mariadb"

# Create the web user group and user with ID 500
RUN microdnf install -y shadow-utils tzdata && \
    groupadd -r -g 500 www-user && \
    useradd -r -g www-user -u 500 -d /var/lib/www-user -s /sbin/nologin -c 'Web User' www-user && \
    install -d -m 0750 -o www-user -g www-user /var/lib/www-user

# Install any required dependencies for the container to operate
RUN rpm --install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    rpm --install https://rpms.remirepo.net/enterprise/remi-release-9.rpm && \
    microdnf module enable -y php:remi-${PHP_VERSION} && \
    eval microdnf install -y ca-certificates gettext nginx php-{$PHP_MODULES} \
        python3 python3-pip tini ${EXTRA_PACKAGES} && \
    pip3 install yacron && \
    microdnf clean all && \
    pip3 cache purge

# Copy contents to root directory
COPY ./root/ /

# Export a persistent volume for caddy to store persistent data
VOLUME [ "/var/lib/caddy" ]

WORKDIR /var/www/html

# Let tini execute /entrypoint. This allows proper reaping of processes
#USER caddy
ENTRYPOINT [ "/usr/bin/tini", "--", "/entrypoint.sh" ]
CMD [ "start-web" ]

# Build phase of the container
# This is where composer is added and pterodactyl properly setup
FROM base as build

ARG VERSION
ARG GIT_BRANCH=release/${VERSION}

ENV VERSION=${VERSION}
ENV NODE_OPTIONS=--openssl-legacy-provider

RUN \
    microdnf install -y findutils git yarnpkg

RUN \
    git clone https://github.com/pterodactyl/panel ./ --depth 1 --branch ${GIT_BRANCH} && \
    rm .git -rf && \
    chmod -R 755 storage/* bootstrap/cache && \
    find storage -type d > .storage.tmpl && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    cp .env.example .env && \
    composer install --ansi --no-dev --optimize-autoloader && \
    chown -R www-user:www-user *;

RUN \
    yarn install --production && \
    yarn add cross-env && \
    yarn run build:production && \
    rm -rf node_modules

# Remove persistent data folders as they will be symlinked during runtime.
RUN rm .env ./storage -rf

# Final Production phase of the controller
# All build requirements get scrapped as to maintain a small image
FROM base as production

ARG VERSION
ENV VERSION=${VERSION}

COPY --from=build --chown=www-user:www-user /var/www /var/www

# Symlink storage, config and cache to /data
RUN \
    ln -s /data/storage storage; \
    ln -s /data/pterodactyl.conf .env;

VOLUME [ "/data" ]
