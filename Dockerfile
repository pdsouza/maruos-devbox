FROM pdsouza/maruos:maru-0.7

# extra deps
RUN apt-get update && apt-get -q -y install \
    sudo \
&& apt-install libssl-dev -q -y \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

# create default user
ARG user=dev
ARG group=dev
ARG uid=1000
ARG gid=1000
RUN groupadd -g ${gid} ${group} \
    && useradd -u ${uid} -g ${gid} -m -s /bin/bash ${user} \
    && adduser ${user} sudo && echo "${user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-marudev

# drop root privileges
USER ${user}
ENV USER=${user}
WORKDIR /home/${user}

# get repo
RUN mkdir ~/.bin && echo 'export PATH=~/.bin:$PATH' > ~/.bashrc \
    && curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.bin/repo \
    && chmod a+x ~/.bin/repo

# copy useful scripts
COPY scripts/ scripts/
