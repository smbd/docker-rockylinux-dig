##### build #####
ARG ROCKY_REL

FROM rockylinux/rockylinux:${ROCKY_REL} as builder

ARG ROCKY_REL
ARG BIND_VER

RUN dnf install -y openssl-devel wget \
 && dnf groupinstall -y "Development Tools" \
 && dnf install -y --disablerepo=extras --enablerepo=powertools,devel libnghttp2-devel libuv-devel libcap-devel userspace-rcu-devel \
 && rm -rf /var/cache/dnf/* \
 && dnf clean all

RUN wget https://ftp.iij.ad.jp/pub/network/isc/bind9/${BIND_VER}/bind-${BIND_VER}.tar.xz
RUN tar xf bind-${BIND_VER}.tar.xz

WORKDIR bind-${BIND_VER}
RUN ./configure --prefix=/usr/local/bind-${BIND_VER} \
 --disable-geoip --enable-doh --disable-dnstap \
 && make -j12 && make install

RUN cd /usr/local/bind-${BIND_VER} \
 && strip -g bin/dig bin/delv lib/lib*.so \
 && rm -r lib/*.la lib/bind/

##### main #####
FROM rockylinux/rockylinux:${ROCKY_REL}-minimal

ARG BIND_VER

LABEL maintainer="Mitsuru Shimamura <smbd.jp@gmail.com>"

ENV LD_LIBRARY_PATH /usr/local/bind-${BIND_VER}/lib

COPY --from=builder /usr/local/bind-${BIND_VER}/lib/  /usr/local/bind-${BIND_VER}/lib/
COPY --from=builder /usr/local/bind-${BIND_VER}/bin/dig /usr/local/bind-${BIND_VER}/bin/
COPY --from=builder /usr/local/bind-${BIND_VER}/bin/delv /usr/local/bind-${BIND_VER}/bin/

# update all packages
RUN microdnf update -y

RUN microdnf install -y --disablerepo=extras --enablerepo=powertools openssl libnghttp2 libuv libcap userspace-rcu \
 && rm -rf /var/cache/yum/* \
 && microdnf clean all

# install in /usr/local/bin
RUN for command in dig delv ; do ln -s /usr/local/bind-${BIND_VER}/bin/${command} /usr/local/bin/${command} ; done

ENTRYPOINT ["/usr/local/bin/dig"]
