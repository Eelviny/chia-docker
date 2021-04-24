#!/bin/bash

rm /tmp/*.tmp
while [ ! -f /root/stoprun ]
do
  chia plots create -r 4 -t /tmp -d /plots
done
echo Stopfile found, exiting
