From alpine:3.6

VOLUME /var/configuration
COPY / /var/configuration
WORKDIR /var/configuration

RUN apk add --update bc jq sqlite bash

RUN ls /var/configuration/

ENTRYPOINT /var/configuration/config_generator.sh --root=$ROOT --styles=$STYLES --fonts=$FONTS --tiles=$TILES --sprites=$SPRITES
