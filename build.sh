#!/bin/bash

IS_LATEST=true
ROCKY_REL_VER=8.6
ROCKY_REL_DATE=20220707
BIND_VER=9.19.17

docker build --progress=plain --no-cache -t rockylinux-dig:${ROCKY_REL_VER}-${BIND_VER} --build-arg ROCKY_REL=${ROCKY_REL_VER}.${ROCKY_REL_DATE} --build-arg BIND_VER=${BIND_VER} .

if "${IS_LATEST}" == true ; then
  docker build -t rockylinux-dig:latest --build-arg ROCKY_REL=${ROCKY_REL_VER}.${ROCKY_REL_DATE} --build-arg BIND_VER=${BIND_VER} .
fi
