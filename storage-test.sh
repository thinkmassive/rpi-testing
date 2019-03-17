#!/bin/bash

DEV=$1
COUNT=${2:-3}
MNT=${3:-/mnt}
DIR=${4:-$MNT/benchmark}
NAME=$(lsblk -no UUID $DEV)

[ ! -b "$DEV" ] && echo "no block device $DEV" && exit 1
sudo mount $DEV $MNT
sudo mkdir -p $DIR
sudo chown -R pi:pi $DIR
cd $DIR && rm -f *.out tmp-* || exit 2

echo "Beginning benchmark: DEV=$DEV COUNT=$COUNT DIR=$DIR" | tee device.out

touch $DIR/in-progress
while [ -f $DIR/in-progress ]; do
  echo -e "\n$(date '+%Y%m%d-%R:%S')" | tee -a sensors.out
  vcgencmd measure_clock arm >> sensors.out
  vcgencmd measure_temp >> sensors.out
  sleep 10
done &

sudo hdparm -I $DEV >> device.out
echo '' >> device.out
sudo lsblk -f $DEV >> device.out
echo '' >> device.out
sudo fdisk -l $DEV >> device.out

# Write 128 MB files
for i in $(seq 1 $COUNT); do
  echo "Writing $i of $COUNT"
  echo -n "$i " >> write.out
  dd if=/dev/zero of=tmp-$i bs=4k count=32768 conv=fdatasync 2>&1 | grep copied >> write.out
done

# Flush file cache with 1 GB file
echo "Flusing file cache"
dd if=/dev/zero of=tmp-clearcache bs=4k count=262144 2>/dev/null

# Read 128 MB file
for i in $(seq 1 $COUNT); do
  echo "Reading $i of $COUNT"
  echo -n "$i " >> read.out
  dd if=tmp-$i of=/dev/null bs=4k 2>&1 | grep copied >> read.out
done

rm $DIR/in-progress
[ ! -z $NAME ] && mkdir -p ~/benchmark/$NAME && cp -a *.out ~/benchmark/$NAME/

sed -i '/storage-test\.sh/d' ~/.bashrc
cd ~/benchmark/$NAME
pwd
sudo shutdown -h now
