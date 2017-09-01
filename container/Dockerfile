# Public-Dataset-AG
#
# VERSION	1.0

FROM	ubuntu:14.04
MAINTAINER	Illyoung Choi <iychoi@email.arizona.edu>

##############################################
# Setup environment
##############################################
ENV LD_LIBRARY_PATH /usr/local/lib

##############################################
# Setup a Syndicate account
##############################################
ENV USER syndicate
ENV HOME /home/$USER

RUN useradd $USER && echo 'syndicate:syndicate' | chpasswd && \
    echo "syndicate ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir /home/$USER && \
    chown -R $USER:$USER $HOME

WORKDIR $HOME

##############################################
# Setup Syndicate
##############################################
ENV APT_KEY butler_opencloud_cs_arizona_edu_pub.gpg

# Prep apt to be able to download over https
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --allow-unauthenticated --no-install-recommends \
    apt-transport-https ca-certificates fuse \
    wget curl unzip build-essential ssh && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt /var/lib/cache /var/lib/log && \
    groupadd -f fuse && \
    usermod -aG fuse $USER

# Copy over and trust https cert
COPY butler.crt /usr/local/share/ca-certificates
COPY $APT_KEY /tmp/

RUN update-ca-certificates && \
    apt-key add /tmp/$APT_KEY && \
    echo "deb https://butler.opencloud.cs.arizona.edu/repos/release/syndicate syndicate main" > /etc/apt/sources.list.d/butler.list

# Install Syndicate
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --allow-unauthenticated --no-install-recommends \
    syndicate-core \
    syndicate-ag \
    syndicate-fs-driver && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt /var/lib/cache /var/lib/log

COPY init_container.sh /usr/bin/
COPY start_ag.sh /usr/bin/
RUN chmod 777 /usr/bin/init_container.sh && \
    chmod 777 /usr/bin/start_ag.sh

USER $USER

CMD bash -C '/usr/bin/init_container.sh'
