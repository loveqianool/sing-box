FROM alpine

RUN apk add --no-cache wireguard-tools curl tzdata unzip iproute2 iputils-ping nftables ca-certificates

RUN sed -i "s:sysctl -q net.ipv4.conf.all.src_valid_mark=1:echo Skipping setting net.ipv4.conf.all.src_valid_mark:" /usr/bin/wg-quick \
 && sed -i "s:resolvconf -a:echo Skipping setting resolvconf -a:" /usr/bin/wg-quick \
 && sed -i "s:resolvconf -d:echo Skipping setting resolvconf -d:" /usr/bin/wg-quick \
 && sed -i "s: resolvconf -l:echo Skipping setting resolvconf -l:" /usr/bin/wg-quick \
 RUN wget https://github.com/malikshi/sing-box-geo/releases/latest/download/geosite.db \
 -O /usr/local/bin/geosite.db \
 && wget https://github.com/malikshi/sing-box-geo/releases/latest/download/geoip.db \
 -O /usr/local/bin/geoip.db
 && curl https://developers.cloudflare.com/cloudflare-one/static/documentation/connections/Cloudflare_CA.pem \
 -o /usr/local/share/ca-certificates/Cloudflare_CA.pem \
 && chmod 644 /usr/local/share/ca-certificates/Cloudflare_CA.pem \
 && update-ca-certificates
 
RUN ARCH=$(arch) && \
if [ "$ARCH" = "aarch64" ]; then ARCH=arm64; else ARCH=amd64-v3; fi && \
l=https://github.com/loveqianool/sing-box/releases/download/$(curl -s "https://api.github.com/repos/loveqianool/sing-box/releases" | grep -m 1 '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')/sing-box-linux-$ARCH && \
curl -sL $l -o /usr/local/bin/sing-box && \
chmod +x /usr/local/bin/sing-box

COPY --from=ghcr.io/shadowsocks/ssserver-rust /usr/bin/ssserver /usr/bin/

RUN <<EOF cat >> /entrypoint.sh
#!/bin/sh
if [[ -d "/etc/wireguard" ]]; then
    chmod 600 /etc/wireguard/wg0.conf
    wg-quick up wg0
    sleep 3
else
    echo "WireGuard folder does not exist."
fi

if [[ -f "/etc/sing-box/config.json" ]]; then
    sing-box run -c /etc/sing-box/config.json
else
    echo "sing-box config.json file does not exist."
fi

if [[ -f "/etc/shadowsocks-rust/config.json" ]]; then
    ssserver -v -c /etc/shadowsocks-rust/config.json
else
    echo "ss config.json file does not exist."
fi
EOF

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
