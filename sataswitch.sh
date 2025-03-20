#! /bin/sh 

# extremely rough driver script for PALS v1 
# Cosmin Deaconu <cozzyd@kicp.uchicago.edu>
# Usage:  ./sataswitch.sh [port=off] [i2cbus=1] [addr=0x74] 
# For preemphasis/equalizer you have to edit this script for now
# if port is anything outside of 0-7, everything will be turned off 


port=${1-off}
bus=${2-1}
addr=${3-0x74}

# values of configuration nibble 
CONFNIBBLE_VAL=0x0
# direction of configuration nibble (0 = output, 1 = input) 
CONFNIBBLE_DIR=0xf

BYTE0=0x0
BYTE1=0x0

# echo Initialising ports on bus $bus, address $addr
# i2cset -y $bus $addr 0x02 0x00
# i2cset -y $bus $addr 0x03 0x00

# i2cset -y $bus $addr 0x06 0x00
# i2cset -y $bus $addr 0x07 0x00

case $port in
  0) 
    BYTE0=0x0a;
    BYTE1=0x8;;
  1) 
    BYTE0=0x06;
    BYTE1=0x9;;
  2) 
    BYTE0=0x0e;
    BYTE1=0xa;;
  3) 
    BYTE0=0x21;
    BYTE1=0xb;;
  4) 
    BYTE0=0x11;
    BYTE1=0xc;;
  5) 
    BYTE0=0x31;
    BYTE1=0xd;;
  6) 
    BYTE0=0x83;
    BYTE1=0xe;;
  7) 
    BYTE0=0x43;
    BYTE1=0xf;;
*) 
echo Turning off;;
esac 

#OUTPUTS0=`printf "0x%x" $((~BYTE0 & 0xff))`
#OUTPUTS1=`printf "0x%x" $((~BYTE1 & 0xff))`
BYTE1=`printf "0x%x" $(( (BYTE1 | (CONFNIBBLE_VAL << 4)) & 0xff))`
BYTE1OUTPUT=`printf "0x%x" $(( (CONFNIBBLE_DIR << 4) & 0xff ))`

echo BYTE0: $BYTE0,  BYTE1: $BYTE1 BYTE1OUTPUT: $BYTE1OUTPUT

#byte 0 set values
echo i2cset -y $bus $addr 0x02 $BYTE0
i2cset -y $bus $addr 0x02 $BYTE0
#byte 0 set all as outputs
echo i2cset -y $bus $addr 0x06 0x0 
i2cset -y $bus $addr 0x06 0x0 

#byte 1 set values
echo i2cset -y $bus $addr 0x03 $BYTE1
i2cset -y $bus $addr 0x03 $BYTE1
#byte 1 set first nibble as outputs, second nibble as specified by CONFNIBBLE_DIR
echo i2cset -y $bus $addr 0x07 $BYTE1OUTPUT
i2cset -y $bus $addr 0x07 $BYTE1OUTPUT
