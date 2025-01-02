FROM debian:bookworm

RUN apt update -yqq
RUN apt upgrade -yqq
RUN apt install -yqq build-essential
RUN apt install -yqq gcc-arm-none-eabi

WORKDIR /app