FROM docker:20.10.22-dind

ARG proxy
ARG no_proxy
ARG host_uid
ARG host_gid

ENV http_proxy=$proxy
ENV https_proxy=$proxy
ENV NO_PROXY=$no_proxy
ENV PATH $PATH:/usr/sbin

RUN apk update && apk add --no-cache nodejs npm curl shadow sudo

RUN npm install -g serverless@3.26.0

COPY sls /opt/sls
WORKDIR /opt/sls
RUN npm install

RUN addgroup -g 13567 sysadmin && echo "%sysadmin ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/sysadmin
RUN groupadd -g $host_gid app && \
    useradd -u $host_uid -o -m -g $host_gid -s /bin/bash app && \
    usermod -aG sysadmin app
RUN chown -R app:app /opt

ENTRYPOINT []

CMD ["/bin/bash"]