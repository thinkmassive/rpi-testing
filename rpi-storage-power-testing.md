# Raspberry Pi Mass Storage Power Consumption

## Mass Storage Devices

### USB Flash Drive
- SanDisk 32 GB

### 2.5" HDD via USB-SATA adapter
- Seagate 1 TB

### 2.5" SSD via USB-SATA adapter
- SanDisk 480 GB

### m.2 SSD via USB-C
- Samsung T5 512 GB


## Testing Environment
The hardware environment remains as consistent as possible between mass storage device tests. Each test began with the DC UPS fully charged, and it remained connected to its AC PSU throughout testing. After initial setup of the Pi, all peripherals were disconnected except the mass storage device under test.

### Hardware
- Raspberry Pi 3B+ w/small heatsinks
- ATP [aMLC 4 GB microSD](https://www.digikey.com/en/product-highlight/a/atp/advancedmlc-amlc-microsd-microsdhc-cards) *
- TalentCell [YB1206000-USB](https://www.talentcell.com/products/12v-battery/12v-battery-12000mah.html)
- Drok [USB multimeter](https://www.droking.com/5in1-usb-multimeter-usb-3.0-tester-voltage-current-power-capacity-charging-panel-meter-for-mobile-phone-tablet-pc-pda-mp3-mp4)
- Anker USB power supply
- Anker USB cables

* Note about ATP aMLC flash: [power cycle boot testing](https://forums.balena.io/t/raspberry-pi-atp-amlc-microsd-cards-automated-powercycling-tests/4756)

### Software
- Raspbian Stretch Lite (Nov 2018)
- Utilities
  - `hdparm`
  - `iostat`
  - `vgencmd` ([usage](https://elinux.org/RPI_vcgencmd_usage))

## Testing Procedure
Starting from a fresh install of Raspbian, apply updates and configure auto-login:
```bash
sudo apt update
sudo apt upgrade -y
sudo apt install hdparm
echo -e "[Service]\nExecStart=-/sbin/agetty --autologin pi --noclear %I 38400 linux" | \
  sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf
sudo systemctl enable getty@tty1.service
sudo reboot
```
Copy the following script to `/home/pi/storage-test.sh`:
```bash
#!/bin/bash

DEV=$1
COUNT=${2:-10}
MNT=${3:-/mnt}
DIR=${4:-$MNT/benchmark}
NAME=$(lsblk -no UUID $DEV)

[ ! -b "$DEV" ] && echo "no block device $DEV" && exit 1
sudo mount $DEV $MNT
sudo mkdir -p $DIR
sudo chown -R pi:pi $DIR
cd $DIR

echo "Beginning benchmark: DEV=$DEV COUNT=$COUNT DIR=$DIR"
rm -f *.out tmp-*

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
  dd if=tmp-$i of=/dev/null bs=4k 2>&1 | grep copied >> read.out
done

sed -i '/storage-test\.sh/d' ~/.bashrc
[ ! -z $NAME ] && mkdir -p ~/$NAME && cp -a *.out ~/$NAME 

sudo shutdown -h now
```

For each mass storage device, modify `/home/pi/.bashrc` to auto-run the benchmark script with the appropriate partition:
```bash
echo "~/storage-test.sh /dev/sda1 100" >> ~/.bashrc

```
The benchmark script will shutdown the Pi upon completion. It also removes the `storage-test.sh` entry from `/home/pi/.bashrc` so you can access the shell after a reboot.

## Results

| Device    | duration | energy   |
|-----------|----------|----------|
| idle      |  14m 30s |  484 mWh |
| SATA SSD  |  12m 47s |  840 mWh |
| USB flash |  21m 39s | 1115 mWh |
| SATA HDD  |  14m 49s | 1376 mWh |
| USB SD    |  36m 24s | 1475 mWh |

### Preview tweets
1/? To understand how mass storage devices impact power consumption on RPi, I scripted a benchmark to run at boot: write 100x 128MB files, flush cache w/1GB file, read 100x 128MB files, shutdown. Measure duration and energy consumed.
2/? Testbed: Raspberry Pi 3B+, ATP aMLC 4GB micro SD, Raspbian Stretch Lite 2018-11, TalentCell 5V/12Ah DC UPS, StarTech USB-SATA cable (only connected for SATA devices)
3/? Devices Tested: baseline: RPi 3B+, Raspbian idling, no mass storage  SATA SSD: SanDisk SSD Plus 480GB  USB flash: SanDisk Ultra Fit 32GB  SATA HDD Seagate BarraCude 2.5" 1TB  USB SD: Samsung Pro Endurance 32GB
4/? Results:  idle: 14m 30s, 484 mWh  SATA SSD: 12m 47s, 840 mWh  USB flash: 21m 39s, 1115 mWh  SATA HDD: 14m 49s, 1376 mWh  USB SD: 36m 24s, 1475 mWh
