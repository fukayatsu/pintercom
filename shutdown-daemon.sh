#!/bin/sh
BUTTON=25 # shutdown button     
BUZZER=4
LED=17

PUSHTIME=3

echo "$BUTTON" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio$BUTTON/direction
echo "high" > /sys/class/gpio/gpio$BUTTON/direction

echo "$LED" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio$LED/direction

echo "$BUZZER" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio$BUZZER/direction

echo 1 > /sys/class/gpio/gpio$BUZZER/value
sleep 0.2
echo 0 > /sys/class/gpio/gpio$BUZZER/value

cnt=0
while [ $cnt -lt $PUSHTIME ] ; do
  data=`cat /sys/class/gpio/gpio$BUTTON/value`
  if [ "$data" -eq "0" ] ; then
    cnt=`expr $cnt + 1`
  else
    cnt=0
  fi
  sleep 1
done

echo 1 > /sys/class/gpio/gpio$BUZZER/value
sleep 0.5
echo 0 > /sys/class/gpio/gpio$BUZZER/value

echo 1 > /sys/class/gpio/gpio$LED/value

shutdown -h now

