From alpine:3.6

ENV ROOT="/var/local/efs-dev/vectortiles"
ENV STYLES="styles"
ENV TILES="mbtiles"
ENV FONTS="fonts"
ENV SPRITES="sprites"

VOLUME /var/configuration
COPY / /var/configuration
WORKDIR /var/configuration

RUN apk add --update bc jq sqlite bash

RUN ls /var/configuration/

ENTRYPOINT ["bash","/var/configuration/config_generator.sh", "--root=/var/local/efs-dev/vectortiles", "--styles=styles", "--fonts=fonts", "--tiles=mbtiles", "--sprites=sprites"]
