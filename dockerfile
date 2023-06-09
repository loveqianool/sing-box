FROM alpine

RUN apk add --no-cache wireguard-tools curl tzdata unzip iproute2 openresolv iputils-ping nftables ca-certificates

RUN sed -i "s:sysctl -q net.ipv4.conf.all.src_valid_mark=1:echo Skipping setting net.ipv4.conf.all.src_valid_mark:" /usr/bin/wg-quick \
 && curl https://developers.cloudflare.com/cloudflare-one/static/documentation/connections/Cloudflare_CA.pem \
 -o /usr/local/share/ca-certificates/Cloudflare_CA.pem \
 && chmod 644 /usr/local/share/ca-certificates/Cloudflare_CA.pem \
 && update-ca-certificates
 
RUN ARCH=$(arch) && \
if [ "$ARCH" = "aarch64" ]; then ARCH=arm64; else ARCH=amd64-v3; fi && \
l=https://github.com/loveqianool/sing-box/releases/download/$(curl -s "https://api.github.com/repos/loveqianool/sing-box/releases" | grep -m 1 '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')/sing-box-linux-$ARCH && \
curl -sL $l -o /usr/local/bin/sing-box && \
chmod +x /usr/local/bin/sing-box

CMD ["sing-box", "run", "-c", "/etc/sing-box/config.json"]
