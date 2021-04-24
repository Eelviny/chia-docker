#!/bin/bash

chia init
chia keys add -f /root/keyfile
rm /root/keyfile
chia plots add -d /plots
chia start farmer
chia plots check
while [ 1 ]
do
  chia show -s
  chia wallet show
  sleep 1h
done
