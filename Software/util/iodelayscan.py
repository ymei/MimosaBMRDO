from command import *
import socket
import time
from i2c_control import *

host = '192.168.2.3'
port = 1024
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host,port))

cmd = Cmd()
#s.setblocking(1)
ioDelayValue = 0x0
ioDelayValue_ = 0
sums = 0
cnt = 0
iodelay_average = 0
boundary = 0
setvalue = 0

# -- set threshold
i2c_ltc2635_thre_vchip(s,cmd,0x5ff)
i2c_ltc2635_thre_vmim(s,cmd,0x5ff)
time.sleep(0.3)
# -- reset latchup
i2c_pcf8574_reset_latchup(s,cmd)
time.sleep(0.3)
i2c_pcf8574_read_latchup(s,cmd)
time.sleep(1)
# write to JTAG
ret = cmd.cmd_write_register(3,0x4)
s.sendall(ret)
#ret = cmd.cmd_write_memory_file("/home/wangdong/mapstest/JTAG_files/S1_L2.dat")
ret = cmd.cmd_write_memory_file("S1_L2.dat")
s.sendall(ret)
time.sleep(0.2)
ret = cmd.cmd_send_pulse(0x8)
s.sendall(ret)
time.sleep(1)

for i in range(32):
    # write IOdelay values
    ret = cmd.cmd_write_register(4,ioDelayValue)
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x1)
    s.send(ret)
    # send ChIP_START
    ret = cmd.cmd_send_pulse(0x2)
    s.send(ret)
    # read Serdes Error
    ret = cmd.cmd_read_status(1) # read data
    s.send(ret)
    data = s.recv(4)
    serdesErr = ord(data[3])
    #print serdesErr & 0x2

    if ((serdesErr & 0x2) > 0):
        if (i==0):
            boundary = 1
        if ((boundary == 1) & (ioDelayValue_ > 39)):
            sums += (ioDelayValue_-80)
        else:
            sums += ioDelayValue_
        cnt += 1

    ioDelayValue += 0x0202
    ioDelayValue_ +=2
    if (ioDelayValue_ == 32):
        ioDelayValue_ = 40


iodelay_average = sums/cnt
setvalue = (iodelay_average+40)%80
if(setvalue > 75):
    setvalue = 0
elif(setvalue > 71):
    setvalue = 63
elif(setvalue > 39):
    setvalue -= 8
elif(setvalue > 35):
    setvalue = 32
elif(setvalue > 31):
    setvalue = 31

print "avg: ",hex(iodelay_average), \
    "opt: ",hex(setvalue)

# load IOdelay values
ret = cmd.cmd_write_register(4,setvalue)
s.send(ret)
time.sleep(0.1)
ret = cmd.cmd_send_pulse(0x1)
s.send(ret)
time.sleep(0.1)
# send ChIP_START
ret = cmd.cmd_send_pulse(0x2)
s.send(ret)
time.sleep(0.1)
# read Serdes Error
ret = cmd.cmd_read_status(1) # read data
s.send(ret)
data = s.recv(4)
serdesErr = ord(data[3])
print "Error = ", hex(serdesErr & 0x2)

print "Finished ..."
