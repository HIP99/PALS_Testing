# PALS testing code

## sataswitch.sh
Takes the desired port as an input which should turn on connected hard drive and allow data transfer via SATA.

`./sataswitch.sh [port=off] [i2cbus=1] [addr=0x74]`

No input will turn all of the ports off

## satatest.sh
Since the PCBs ports may or may not be working, this program loops though the connections listed in sata_config.txt to check for drive activity. This does not test bulk read and writes, only whether a computer can communicate to the hard-drives via a SATA connection on a PCB.

This outputs a sata_test_summary since this may take a couple minutes

### Notes
Maybe include detaching drives into the sataswitch instead of satatest.