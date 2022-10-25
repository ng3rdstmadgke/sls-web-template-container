FROM public.ecr.aws/lambda/python:3.8

ARG proxy
ARG no_proxy
ARG host_uid
ARG host_gid

ENV http_proxy=$proxy
ENV https_proxy=$proxy
ENV NO_PROXY=$no_proxy
ENV PATH $PATH:/usr/sbin

RUN printenv

# update package
RUN yum update -y && \
    yum install -y locales gcc unzip jq curl shadow-utils vim tmux sudo wget && \
    yum install -y iputils-ping net-tools less groff

# install mysql
RUN rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 && \
    wget https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm && \
    yum localinstall -y mysql80-community-release-el7-1.noarch.rpm && \
    yum install -y mysql-community-server

# set timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# install awscli
RUN cd /tmp && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -r aws awscliv2.zip

# install nodejs
RUN curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
RUN yum install -y nodejs

RUN mkdir -p /opt/app
WORKDIR /opt/app

# pip install
COPY requirements.txt .
RUN pip3 install --upgrade pip && pip3 install -r requirements.txt

COPY front front

RUN cd /opt/app/front && \
  npm update -g npm && \
  npm install && \
  npm run generate

COPY . .

RUN groupadd -g 13567 sysadmin && echo "%sysadmin ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/sysadmin

RUN groupadd -g $host_gid app && \
    useradd -u $host_uid -o -m -g $host_gid -s /bin/bash app && \
    usermod -aG sysadmin app

RUN chown -R app:app /opt

ENTRYPOINT []

CMD ["/opt/app/docker/dev/shell-entrypoint.sh"]