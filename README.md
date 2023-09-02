# Docker Image for Maru OS Development

[![Build Status](https://travis-ci.org/pdsouza/maruos-devbox.svg?branch=master)](https://travis-ci.org/pdsouza/maruos-devbox)
 [![Docker Pulls](https://img.shields.io/docker/pulls/pdsouza/maruos-devbox.svg)](https://hub.docker.com/r/pdsouza/maruos-devbox/) 

Get the latest image:

    $ docker pull pdsouza/maruos-devbox:maru-0.7

Basic usage:

    $ docker run --privileged -it \
        -v ~/path/to/$WORKSPACE:/var/maru \
        pdsouza/maruos-devbox

Fancy usage (custom hostname, USB access for adb/fastboot within container):

    $ docker run --privileged -it \
        -h my-cool-hostname \
        -v /dev/bus/usb:/dev/bus/usb \
        -v ~/path/to/$WORKSPACE:/var/maru \
        pdsouza/maruos-devbox:maru-0.7

## Contributing

See the [main Maru OS repository](https://github.com/maruos/maruos) for more
info.

## Licensing

[Apache 2.0](LICENSE)
