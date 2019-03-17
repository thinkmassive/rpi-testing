#!/bin/bash

DIR=~/benchmark/idle

sed -i '/idle-test\.sh/d' ~/.bashrc

sudo mkdir -p $DIR
sudo chown -R pi:pi $DIR
cd $DIR && rm -f *.out tmp-* || exit 2

echo "Beginning benchmark: idle DIR=$DIR" | tee device.out

touch $DIR/in-progress
while [ -f $DIR/in-progress ]; do
  echo -e "\n$(date '+%Y%m%d-%R:%S')" | tee -a sensors.out
  vcgencmd measure_clock arm >> sensors.out
  vcgencmd measure_temp >> sensors.out
  sleep 10
done &

sleep 767

rm $DIR/in-progress

sudo shutdown -h now
