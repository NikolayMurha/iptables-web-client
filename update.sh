#!/bin/sh
rm -rf ./pkg/*
rake build
gem uninstall iptables-web -q
gem install --local ./pkg/*.gem
