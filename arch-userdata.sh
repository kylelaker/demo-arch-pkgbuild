#!/usr/bin/env bash
pacman -Syu --no-confim
# OpenSSH ignores connections after update to 8.2
systemctl restart openssh

pacman -Syu --no-confirm podman base-devel sudo aws-cli
