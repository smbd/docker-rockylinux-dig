##### build #####
ARG ROCKY_REL=9.3
ARG BIND_VER=9.20.6

FROM rockylinux/rockylinux:${ROCKY_REL} AS builder

ARG ROCKY_REL
ARG BIND_VER

RUN --mount=type=cache,sharing=locked,target=/var/cache/yum \
 dnf install -y openssl-devel wget \
 && dnf groupinstall -y "Development Tools" \
 && dnf install -y --disablerepo=extras --enablerepo=crb,devel libnghttp2-devel libuv-devel libcap-devel userspace-rcu-devel libidn2-devel

RUN wget -q https://ftp.iij.ad.jp/pub/network/isc/bind9/${BIND_VER}/bind-${BIND_VER}.tar.xz
RUN tar -x -f bind-${BIND_VER}.tar.xz -C /tmp

WORKDIR /tmp/bind-${BIND_VER}
RUN ./configure --prefix=/usr/local/bind-${BIND_VER} \
 --disable-geoip --enable-doh --disable-dnstap --with-libidn2 \
 && make -j12 && make install

RUN cd /usr/local/bind-${BIND_VER} \
 && strip -g bin/dig bin/delv lib/lib*.so \
 && rm -r lib/*.la lib/bind/

##### main #####
FROM rockylinux/rockylinux:${ROCKY_REL}-minimal

ARG BIND_VER

ENV LD_LIBRARY_PATH=/usr/local/bind-${BIND_VER}/lib

COPY --from=builder /usr/local/bind-${BIND_VER}/lib/  /usr/local/bind-${BIND_VER}/lib/
COPY --from=builder /usr/local/bind-${BIND_VER}/bin/dig /usr/local/bind-${BIND_VER}/bin/
COPY --from=builder /usr/local/bind-${BIND_VER}/bin/delv /usr/local/bind-${BIND_VER}/bin/

# update all packages
RUN --mount=type=cache,sharing=locked,target=/var/cache/yum \
 microdnf install -y --disablerepo=extras --enablerepo=crb openssl libnghttp2 libuv libcap userspace-rcu libidn2

# install in /usr/local/bin
RUN for command in dig delv ; do ln -s /usr/local/bind-${BIND_VER}/bin/${command} /usr/local/bin/${command} ; done

ENTRYPOINT ["/usr/local/bin/dig"]
