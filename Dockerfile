##################################################
# Nginx with Quiche (HTTP/3), Brotli, Headers More
# and ModSec modules.
##################################################
# This is a fork of:
# github.com/ranadeeppolavarapu/docker-nginx-http3
#
# Special in this fork:
# - ModSecurity for nginx (SpiderLabs) with
#   coreruleset
# - HPACK enabled and nginx quiche patch by
#   kn007/patch
# - BoringSSL OCSP enabled with kn007/patch
# - Removed nginx debug build
#
# Thanks to ranadeeppolavarapu/docker-nginx-http3
# for doing the ground work!
##################################################

FROM alpine:edge AS builder

LABEL maintainer="Patrik Juvonen <22572159+patrikjuvonen@users.noreply.github.com>"

ENV NGINX_VERSION 1.23.1
ENV QUICHE_CHECKOUT c3d817474b82bf68829a6f4ae713b118dce55caf
ENV MODSEC_TAG v3/master
ENV MODSEC_NGX_TAG master
ENV NJS_TAG 0.7.6

# Build-time metadata as defined at https://label-schema.org
ARG BUILD_DATE
ARG VCS_REF

RUN set -x; GPG_KEYS=13C82A63B603576156E30A4EA0EA981B66B0D967 \
  && CONFIG="\
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib/nginx/modules \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/var/run/nginx.pid \
  --lock-path=/var/run/nginx.lock \
  --http-client-body-temp-path=/var/cache/nginx/client_temp \
  --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
  --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
  --user=nginx \
  --group=nginx \
  --with-pcre-jit \
  --with-http_ssl_module \
  --with-http_realip_module \
  --with-http_addition_module \
  --with-http_sub_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_mp4_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_random_index_module \
  --with-http_secure_link_module \
  --with-http_stub_status_module \
  --with-http_auth_request_module \
  --with-http_xslt_module=dynamic \
  --with-http_image_filter_module=dynamic \
  --with-http_geoip_module=dynamic \
  --with-http_perl_module=dynamic \
  --with-threads \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-stream_realip_module \
  --with-stream_geoip_module=dynamic \
  --with-http_slice_module \
  --with-mail \
  --with-mail_ssl_module \
  --with-compat \
  --with-file-aio \
  --with-http_v2_module \
  --with-http_v2_hpack_enc \
  --with-http_v3_module \
  --with-openssl=/usr/src/quiche/quiche/deps/boringssl \
  --with-quiche=/usr/src/quiche \
  --add-module=/usr/src/ngx_brotli \
  --add-module=/usr/src/headers-more-nginx-module \
  --add-module=/usr/src/njs/nginx \
  --add-module=/usr/src/nginx_cookie_flag_module \
  --add-module=/usr/src/ModSecurity-nginx \
  --with-cc-opt=-Wno-error \
  --with-select_module \
  --with-poll_module \
  " \
  && addgroup -S nginx \
  && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
  && apk update \
  && apk upgrade \
  && apk add --no-cache ca-certificates openssl \
  && update-ca-certificates \
  && apk add --no-cache --virtual .build-deps \
  gcc \
  libc-dev \
  make \
  pcre-dev \
  zlib-dev \
  linux-headers \
  gnupg \
  libxslt-dev \
  gd-dev \
  geoip-dev \
  perl-dev \
  && apk add --no-cache --virtual .brotli-build-deps \
  autoconf \
  libtool \
  automake \
  git \
  g++ \
  cmake \
  go \
  perl \
  rust \
  cargo \
  patch \
  && apk add --no-cache --virtual .modsec-build-deps \
  libxml2-dev \
  byacc \
  flex \
  libstdc++ \
  libmaxminddb-dev \
  lmdb-dev \
  file \
  && mkdir /usr/src \
  && cd /usr/src \
  && git clone --depth=1 --recursive --shallow-submodules https://github.com/google/ngx_brotli \
  && git clone --depth=1 --recursive --shallow-submodules https://github.com/openresty/headers-more-nginx-module \
  && git clone --branch $NJS_TAG --depth=1 --recursive --shallow-submodules https://github.com/nginx/njs \
  && git clone --depth=1 --recursive --shallow-submodules https://github.com/AirisX/nginx_cookie_flag_module \
  && git clone --recursive https://github.com/cloudflare/quiche \
  && cd /usr/src/quiche \
  && git checkout --recurse-submodules $QUICHE_CHECKOUT \
  && cd /usr/src \
  && wget -q https://raw.githubusercontent.com/kn007/patch/1062e64ead7e1b21a52392cdd02d1d5bc631d231/nginx_with_quic.patch \
  && wget -q https://raw.githubusercontent.com/kn007/patch/cd03b77647c9bf7179acac0125151a0fbb4ac7c8/Enable_BoringSSL_OCSP.patch \
  && git clone --recursive --branch $MODSEC_TAG --single-branch https://github.com/SpiderLabs/ModSecurity \
  && git clone --depth=1 --recursive --shallow-submodules --branch $MODSEC_NGX_TAG --single-branch https://github.com/SpiderLabs/ModSecurity-nginx \
  && git clone --depth=1 https://github.com/coreruleset/coreruleset /usr/local/share/coreruleset \
  && CRS_COMMIT=$(git --git-dir=/usr/local/share/coreruleset/.git rev-parse --short HEAD) \
  && cp /usr/local/share/coreruleset/crs-setup.conf.example /usr/local/share/coreruleset/crs-setup.conf \
  && find /usr/local/share/coreruleset \! -name '*.conf' -type f -mindepth 1 -maxdepth 1 -delete \
  && find /usr/local/share/coreruleset \! -name 'rules' -type d -mindepth 1 -maxdepth 1 | xargs rm -rf \
  && wget -qO nginx.tar.gz https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz \
  && wget -qO nginx.tar.gz.asc https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc \
  && export GNUPGHOME="$(mktemp -d)" \
  && found=''; \
  for server in \
  ha.pool.sks-keyservers.net \
  hkp://keyserver.ubuntu.com:80 \
  hkp://p80.pool.sks-keyservers.net:80 \
  pgp.mit.edu \
  ; do \
  echo "Fetching GPG key $GPG_KEYS from $server"; \
  gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
  done; \
  test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
  gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
  && rm -rf "$GNUPGHOME" nginx.tar.gz.asc \
  && tar -zxC /usr/src -f nginx.tar.gz \
  && rm nginx.tar.gz \
  && cd /usr/src/ModSecurity \
  && ./build.sh \
  && ./configure --with-lmdb --enable-examples=no \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make -j$(getconf _NPROCESSORS_ONLN) install \
  && cd /usr/src/nginx-$NGINX_VERSION \
  && patch -p01 < /usr/src/nginx_with_quic.patch \
  && patch -p01 < /usr/src/Enable_BoringSSL_OCSP.patch \
  && mkdir /root/.cargo \
  && echo $'[net]\ngit-fetch-with-cli = true' > /root/.cargo/config.toml \
  && ./configure $CONFIG --build="docker-nginx-http3-$VCS_REF-$BUILD_DATE ModSecurity-$(git --git-dir=/usr/src/ModSecurity/.git rev-parse --short HEAD) ModSecurity-nginx-$(git --git-dir=/usr/src/ModSecurity-nginx/.git rev-parse --short HEAD) coreruleset-$CRS_COMMIT quiche-$(git --git-dir=/usr/src/quiche/.git rev-parse --short HEAD) ngx_brotli-$(git --git-dir=/usr/src/ngx_brotli/.git rev-parse --short HEAD) headers-more-nginx-module-$(git --git-dir=/usr/src/headers-more-nginx-module/.git rev-parse --short HEAD) njs-$(git --git-dir=/usr/src/njs/.git rev-parse --short HEAD) nginx_cookie_flag_module-$(git --git-dir=/usr/src/nginx_cookie_flag_module/.git rev-parse --short HEAD)" \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make -j$(getconf _NPROCESSORS_ONLN) install \
  && rm -rf /etc/nginx/html/ \
  && mkdir /etc/nginx/conf.d/ \
  && mkdir /etc/nginx/modsec/ \
  && mkdir -p /usr/share/nginx/html/ \
  && install -m644 html/index.html /usr/share/nginx/html/ \
  && install -m644 html/50x.html /usr/share/nginx/html/ \
  && install -m444 /usr/src/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf \
  && install -m444 /usr/src/ModSecurity/unicode.mapping /etc/nginx/modsec/unicode.mapping \
  && ln -s /usr/lib/nginx/modules /etc/nginx/modules \
  && strip /usr/sbin/nginx* \
  && strip /usr/lib/nginx/modules/*.so \
  && strip /usr/local/modsecurity/bin/* \
  && strip /usr/local/modsecurity/lib/*.so.* \
  && strip /usr/local/modsecurity/lib/*.a \
  && rm -rf /etc/nginx/*.default /etc/nginx/*.so \
  && rm -rf /usr/src \
  \
  # Bring in gettext so we can get `envsubst`, then throw
  # the rest away. To do this, we need to install `gettext`
  # then move `envsubst` out of the way so `gettext` can
  # be deleted completely, then move `envsubst` back.
  && apk add --no-cache --virtual .gettext "gettext>=0.21-r2" \
  && mv /usr/bin/envsubst /tmp/ \
  \
  && runDeps="$( \
  scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
  | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
  | sort -u \
  | xargs -r apk info --installed \
  | sort -u \
  )" \
  && apk add --no-cache --virtual .nginx-rundeps $runDeps \
  && apk del .modsec-build-deps \
  && apk del .brotli-build-deps \
  && apk del .build-deps \
  && apk del .gettext \
  && rm -rf /root/.cargo \
  && rm -rf /var/cache/apk/* \
  && mv /tmp/envsubst /usr/local/bin/ \
  # Create self-signed certificate
  && mkdir -p /etc/ssl/private \
  && openssl req -x509 -newkey rsa:4096 -nodes -keyout /etc/ssl/private/localhost.key -out /etc/ssl/localhost.pem -days 365 -sha256 -subj '/CN=localhost'

FROM alpine:edge

COPY --from=builder /usr/sbin/nginx /usr/sbin/
COPY --from=builder /usr/lib/nginx /usr/lib/nginx
COPY --from=builder /usr/share/nginx/html/* /usr/share/nginx/html/
COPY --from=builder /etc/nginx/ /etc/nginx/
COPY --from=builder /usr/local/bin/envsubst /usr/local/bin/
COPY --from=builder /etc/ssl/private/localhost.key /etc/ssl/private/
COPY --from=builder /etc/ssl/localhost.pem /etc/ssl/
COPY --from=builder /usr/local/share/coreruleset /usr/local/share/coreruleset/
COPY --from=builder /usr/local/modsecurity /usr/local/modsecurity/

RUN \
  apk add --no-cache \
  # Bring in tzdata so users could set the timezones through the environment
  # variables
  tzdata \
  # Dependencies
  pcre \
  libgcc \
  libintl \
  # ModSecurity dependencies
  libxml2-dev \
  yajl-dev \
  geoip-dev \
  libstdc++ \
  libmaxminddb-dev \
  lmdb-dev \
  && addgroup -S nginx \
  && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
  # forward request and error logs to docker log collector
  && mkdir -p /var/log/nginx \
  && touch /var/log/nginx/access.log /var/log/nginx/error.log \
  && chown nginx: /var/log/nginx/access.log /var/log/nginx/error.log \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

COPY modsec/* /etc/nginx/modsec/

# Recommended nginx configuration. Please copy the config you wish to use.
# COPY nginx.conf /etc/nginx/
# COPY h3.nginx.conf /etc/nginx/conf.d/

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]

LABEL org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/patrikjuvonen/docker-nginx-http3.git"
