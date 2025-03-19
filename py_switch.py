##Very rough python SATA switching script

import time
# import RPi.GPIO as GPIO

import smbus2
from smbus2 import SMBus, i2c_msg

# import smbus
# from smbus import SMBus

import numpy as np
import random

## This is the SDA/SCL channel number
i2c_ch = 1

# This is the GPIO expander address
expander_address = 0x74

# Default configuration nibble values
CONFNIBBLE_VAL = 0x0
CONFNIBBLE_DIR = 0xf

GPIO_port0 = [0x0A, 0x06, 0x0E, 0x21, 0x11, 0x31, 0x83, 0x43]
GPIO_port1 = [0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF]

## Initialise the bus
bus = SMBus(i2c_ch)

def init_gpios():
    ## This sets the output values of GPIO port 0 to 0
    bus.write_byte_data(expander_address, 0x02, 0x00)
    ## This sets the output values of GPIO port 1 to 0
    bus.write_byte_data(expander_address, 0x03, 0x00)

    ## This turns GPIO port 0 to an output, and drives the values
    bus.write_byte_data(expander_address, 0x06, 0x00)
    ## This turns GPIO port 1 to an output, and drives the values
    bus.write_byte_data(expander_address, 0x07, 0x00)

def run_gpios(GPIO=None):
    if GPIO is None:
        print("Resetting all ports to 0.")
        init_gpios()
        return

    if GPIO < 0 or GPIO >= len(GPIO_port0):
        print(f"Invalid port: {GPIO}. Must be between 0 and {len(GPIO_port0) - 1}.")
        return

    # Get the values for the specified port
    BYTE0 = GPIO_port0[GPIO]
    BYTE1 = GPIO_port1[GPIO]

    BYTE1 = (BYTE1 | (CONFNIBBLE_VAL << 4)) & 0xff
    BYTE1OUTPUT = (CONFNIBBLE_DIR << 4) & 0xff

    # Write the values to the GPIO expander
    print(f"Setting GPIO for port {GPIO}: BYTE0={hex(BYTE0)}, BYTE1={hex(BYTE1)}")
    
    bus.write_byte_data(expander_address, 0x02, BYTE0)
    bus.write_byte_data(expander_address, 0x06, 0x00)

    bus.write_byte_data(expander_address, 0x03, BYTE1)
    bus.write_byte_data(expander_address, 0x07, BYTE1OUTPUT)

init_gpios()

run_gpios(0)

bus.close()
