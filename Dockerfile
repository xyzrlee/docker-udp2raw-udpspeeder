#
# Dockerfile for udp2raw-udpspeeder
#

FROM alpine AS builder

RUN set -ex \
 # Build environment setup
 && apk update \
 && apk upgrade \
 && apk add --no-cache --virtual .build-deps \
      linux-headers \
      git \
      gcc \
      g++ \
      make \
 # Build & install
 && mkdir -p /tmp/repo \
 && cd /tmp/repo \
 && git clone https://github.com/wangyu-/udp2raw-tunnel.git \
 && cd udp2raw-tunnel \
 && make \
 && install udp2raw /usr/local/bin \
 && cd /tmp/repo \
 && git clone git clone https://github.com/wangyu-/UDPspeeder.git \
 && cd UDPspeeder \
 && make \
 && install speederv2 /usr/local/bin


# ------------------------------------------------

FROM alpine

COPY --from=builder /usr/local/bin/udp2raw /usr/local/bin/udp2raw
COPY --from=builder /usr/local/bin/speederv2 /usr/local/bin/speederv2
COPY entrypoint.sh /entrypoint.sh

RUN set -ex \
  && apk add --no-cache libcap iptables ip6tables bash \
  && setcap cap_net_raw+ep /usr/local/bin/udp2raw

USER nobody

RUN set -ex \
  && udp2raw --help \
  && speederv2 --help

ENTRYPOINT [ "/entrypoint.sh" ]

