FROM archlinux:base

RUN pacman -Syu --noconfirm
RUN pacman -S npm git base-devel --noconfirm

RUN useradd  --create-home build && \
    usermod -L build 

WORKDIR /opt
RUN git clone https://aur.archlinux.org/yay.git

WORKDIR /opt/yay
USER root
RUN chown build /opt/yay &&\
    git config --global --add safe.directory /opt/yay

RUN source ./PKGBUILD && \
    pacman -S --noconfirm --needed --asdeps "${makedepends[@]}" "${depends[@]}" 
    
USER build
RUN makepkg -o

USER root
RUN source ./PKGBUILD && \
    srcdir=$(pwd)/src build && \
    srcdir=$(pwd)/src package

RUN userdel build

RUN useradd -m user && \
    usermod -L user && \
    echo "user  ALL = NOPASSWD: ALL" >> /etc/sudoers

USER user
WORKDIR /home/user
ENTRYPOINT "/usr/bin/bash"
