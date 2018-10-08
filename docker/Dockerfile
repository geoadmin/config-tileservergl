From ubuntu:latest

ENV ROOT="/var/local/efs-dev/vectortiles"
ENV STYLES="styles"
ENV TILES="mbtiles"
ENV FONTS="fonts"
ENV SPRITES="sprites"

VOLUME /var/configuration
COPY / /var/configuration
WORKDIR /var/configuration

RUN apt-get -qq update \
&&  DEBIAN_FRONTEND=noninteractive apt-get -y install \
    bc \
    jq \
    sqlite3 \
&& apt-get clean

RUN ls /var/configuration/

ENTRYPOINT ["/bin/bash","/var/configuration/config_generator.sh", "--root=/var/local/efs-dev/vectortiles", "--styles=styles", "--fonts=fonts", "--tiles=mbtiles", "--sprites=sprites"]
