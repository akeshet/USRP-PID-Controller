***** Description of contents:

titus/
	Contains the user interface program for talking to the USRP while it is running.

usrp/
	Contains the FPGA source code.



***** Instructions: 

(Assumes you have a working installation of gnuradio, including the usrper program for controlling the USRP, and a working Python installation to run Titus. This is easiest to accomplish on a Linux machine where these packages can be installed using apt-get or similar.)

1) Plug in your USRP to power, and to the USB port of the computer you plan to control it from.

2) Start Titus by going to the titus directory and typing ./titus.pyw at the command prompt.

3) Titus needs to know the location of 3 files. A "firmware file", a "FPGA bit file" and a "Post-load script". Use the browse button for the 3 file input fields if it is necessary to set the files. The firmware file should be std.ihx, in the top level directory of this repo. The FPGA bit file should be usrp/fpga/toplevel/usrp_std/usrp_std.rbf . The post-load script file should be postloadscript.sh, in the top level directory of this repo.

4) Press the Load Firmware button to program the USRP. This first uploads the USRP microcontroller firmware, then loads the FPGA bit code, and then runs the post load script (the post load script sets various registers of the A/D converters on the USRP to useful values).

5) You may now edit USRP register values in titus. When you change a register value, titus in the background runs a usrper command which sets the register accordingly on the USRP.

6) Sets of register values can be saved and loaded as "configurations", allowing you to save a set of USRP feedback parameters.