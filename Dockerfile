FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       rake \
       ruby \
       wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       build-essential \
       libsqlite3-0 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ARG SWIFT_VER=6.0.2
ARG SWIFT_BASENAME=swift-${SWIFT_VER}-RELEASE-ubuntu22.04
ARG SWIFT_URL=https://download.swift.org/swift-${SWIFT_VER}-release/ubuntu2204/swift-${SWIFT_VER}-RELEASE/${SWIFT_BASENAME}.tar.gz

WORKDIR /opt
RUN wget --quiet "$SWIFT_URL" \
  && tar xf ${SWIFT_BASENAME}.tar.gz \
  && rm ${SWIFT_BASENAME}.tar.gz

RUN ln -s ${SWIFT_BASENAME}/usr /opt/swift

ENV PATH="/opt/swift/bin:${PATH}"

ARG USER
ARG GROUP

RUN groupadd ${USER} \
  && useradd ${USER} -g ${GROUP} -m

USER ${USER}

WORKDIR /home/${USER}/work

ENV IN_CONTAINER=1
ENV LC_ALL=C.utf8
