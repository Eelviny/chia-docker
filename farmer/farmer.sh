#!/bin/bash

chia init
chia keys add -f /root/keyfile
rm /root/keyfile
sed -i 's/localhost/127.0.0.1/g' ~/.chia/mainnet/config/config.yaml # Fix for https://github.com/Eelviny/chia-docker/issues/1
chia plots add -d /plots
chia start farmer
sleep 10
touch ~/.chia/mainnet/log/debug.log
tail -f ~/.chia/mainnet/log/debug.log
