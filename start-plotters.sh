#!/bin/bash

for (( c=1; c<=$1; c++ ))
do
  docker run -d --name plotter$c --privileged -v /scratch/plotter$c:/tmp -v /storage/chia:/plots localhost/chia-plotter:latest
  sleep 2h
done
