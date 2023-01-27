FROM hashicorp/terraform:1.3.7

ARG proxy
ARG no_proxy
ARG host_uid
ARG host_gid

ENV http_proxy=$proxy
ENV https_proxy=$proxy
ENV NO_PROXY=$no_proxy

RUN apk update && apk add --no-cache shadow sudo

RUN addgroup -g 13567 sysadmin && echo "%sysadmin ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/sysadmin
RUN groupadd -g $host_gid app && \
    useradd -u $host_uid -o -m -g $host_gid -s /bin/bash app && \
    usermod -aG sysadmin app

WORKDIR /terraform
RUN chown -R app:app /terraform