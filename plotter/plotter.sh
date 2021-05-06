#!/bin/bash

while [ ! -f /root/stoprun ]
do
  rm /tmp/*.tmp
  chia plots create -r 4 -t /tmp -d /plots
done
rm -f /root/stoprun
echo Stopfile found, exiting
