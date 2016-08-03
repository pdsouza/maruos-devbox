FROM pdsouza/maruos:latest

MAINTAINER Preetam D'Souza <preetamjdsouza@gmail.com>

# create default user
ARG user=dev
ARG group=dev
ARG uid=1000
ARG gid=1000
RUN groupadd -g ${gid} ${group} \
    && useradd -u ${uid} -g ${gid} -m -s /bin/bash ${user} \
    && echo "${user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-marudev

# drop root privileges
USER ${user}

WORKDIR /home/${user}
