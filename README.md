# docker-nginx-http3

[![Docker Pulls](https://img.shields.io/docker/pulls/patrikjuvonen/docker-nginx-http3?color=brightgreen)](https://hub.docker.com/r/patrikjuvonen/docker-nginx-http3)
[![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/patrikjuvonen/docker-nginx-http3)](https://hub.docker.com/r/patrikjuvonen/docker-nginx-http3)
[![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/patrikjuvonen/docker-nginx-http3?color=brightgreen)](https://hub.docker.com/r/patrikjuvonen/docker-nginx-http3)
[![MicroBadger](https://images.microbadger.com/badges/image/patrikjuvonen/docker-nginx-http3.svg)](https://microbadger.com/images/patrikjuvonen/docker-nginx-http3)
![GitHub](https://img.shields.io/github/license/patrikjuvonen/docker-nginx-http3)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](code_of_conduct.md)

Alpine Linux image with nginx `1.19.8` (mainline) with HTTP/2, brotli, NJS, Cookie-Flag, headers, SpiderLabs ModSecurity with coreruleset and BoringSSL with OCSP support. All built on the bleeding edge. Built on the edge, for the edge.

Total size is only about ~38 MB uncompressed and ~14 MB compressed.

This is a fork of [ranadeeppolavarapu/docker-nginx-http3](https://github.com/ranadeeppolavarapu/docker-nginx-http3). Thanks to him for doing the ground work.

Special in this fork:

- [ModSecurity for nginx](https://github.com/SpiderLabs/ModSecurity-nginx) (SpiderLabs) with [coreruleset](https://github.com/coreruleset/coreruleset/)
- BoringSSL OCSP enabled with [kn007/patch](https://github.com/kn007/patch/)
- Removed nginx debug build
- Removed HTTP/3 due to temporary incompatibility issues

Images for this are available on [Docker Hub](https://hub.docker.com/r/patrikjuvonen/docker-nginx-http3).

**Latest**: `docker pull patrikjuvonen/docker-nginx-http3`

## Usage

This is a base image like the default _nginx_ image. It is meant to be used as a drop-in replacement for the nginx base image.

Best practice example Nginx configs are available in this repo. See [_nginx.conf_](nginx.conf) and [_h3.nginx.conf_](h3.nginx.conf).

Example:

```Dockerfile
# Base image
FROM patrikjuvonen/docker-nginx-http3:latest

# Copy your certs.
COPY localhost.key /etc/ssl/private/
COPY localhost.pem /etc/ssl/

# Copy your configs.
COPY nginx.conf /etc/nginx/
COPY h3.nginx.conf /etc/nginx/conf.d/
```

## Contributing

Contributions are welcome. Please feel free to contribute 😊.

## Features

- HTTP/2 (with Server Push)
- HTTP/2
- Brotli compression
- [headers-more-nginx-module](https://github.com/openresty/headers-more-nginx-module)
- [NJS](https://www.nginx.com/blog/introduction-nginscript/)
- [nginx_cookie_flag_module](https://www.nginx.com/products/nginx/modules/cookie-flag/)
- PCRE [JIT compilation](http://nginx.org/en/docs/ngx_core_module.html#pcre_jit) enabled
- Alpine Linux (total size of **10 MB** compressed)

### In this fork

- [ModSecurity for nginx](https://github.com/SpiderLabs/ModSecurity-nginx) (SpiderLabs) with [coreruleset](https://github.com/coreruleset/coreruleset/)
- BoringSSL OCSP enabled with [kn007/patch](https://github.com/kn007/patch/)
- Removed nginx debug build
- Removed HTTP/3 due to temporary incompatibility issues

## Future Additions

Possible additions in the future pending IETF spec approvals.

- [Facebook's zstd over the web](https://tools.ietf.org/html/rfc8478)

## HTTP/2 with Server Push

![alt](https://user-images.githubusercontent.com/7084995/67162942-654ff300-f337-11e9-9dc0-6d7a915d517c.png)
