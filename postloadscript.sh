#!/bin/bash

#./usrper load_firmware ~/gr/share/usrp/rev4/std.ihx
#./usrper load_fpga ~/Desktop/usrp_std.rbf

#Set various register values of the two AD9862 A/D converters on the USRP
#For a full understanding of what these registers do, see the AD9862 datasheet

usrper 9862a_write 1 0
usrper 9862a_write 8 0
usrper 9862a_write 16 0xFF
usrper 9862a_write 5 4
usrper 9862a_write 18 9

usrper 9862b_write 1 0
usrper 9862b_write 8 0
usrper 9862b_write 16 0xFF
usrper 9862b_write 5 4
usrper 9862b_write 18 9

#null out the intrinsic DAC offset
#The values below will be different for different USRPs, so edit them
#If this matters a lot to you
usrper 9862b_write 13 8
usrper 9862b_write 12 254


echo Finished running postload script
