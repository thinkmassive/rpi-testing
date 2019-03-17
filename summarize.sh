#!/bin/bash

[ -z $1 ] && echo "Usage: $0 <dev_uuid>" && exit 0
dev_uuid=$1
path=results/$dev_uuid
summary=$path/summary
date=20190311
#date=$(date '+%Y%m%d')
[ ! -d $path ] && echo "$path not found" && exit 1

grep GiB $path/device.out > $summary

echo "Begin: $(grep $date $path/sensors.out | head -1)" >> $summary
echo "End: $(grep $date $path/sensors.out | tail -1)" >> $summary

echo "Write:" >> $summary
head -1 $path/write.out >> $summary
tail -1 $path/write.out >> $summary

echo "Read:" >> $summary
head -1 $path/read.out >> $summary
tail -1 $path/read.out >> $summary

echo "" >> $summary


grep temp $path/sensors.out | sed "s/temp=\|'C//g" > $path/temp.list
grep frequency $path/sensors.out | sed 's/frequency(.*)=//g' > $path/freq.list
cat $path/write.out | awk '{print $11}' > $path/speed_w.list
cat $path/read.out | awk '{print $11}' > $path/speed_r.list
