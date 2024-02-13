FROM debian:latest

ENV DEBIAN_FRONTEND=noninteractive

# Must use JDK 8 for building release packages to avoid this error:
# java.lang.NoSuchMethodError: java.nio.ByteBuffer.flip()Ljava/nio/ByteBuffer;
# https://github.com/hazelcast/hazelcast/issues/14214

RUN apt-get update && \
  apt-get -y install openjdk-17-jdk ruby git curl make g++

WORKDIR /rubies
COPY release/jruby/install.sh /rubies/
RUN /rubies/install.sh

WORKDIR /app

COPY . .
