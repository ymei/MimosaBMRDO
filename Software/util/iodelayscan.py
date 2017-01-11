from command import *
import socket
import time

host = '192.168.2.3'
port = 1024
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host,port))

cmd = Cmd()

ioDelayValue = 0x0
ioDelayValue_ = 0
sums = []
cnt = []
iodelay_average = []
boundary = []
setvalue = []

for i in range(32):
    # write IOdelay values
    ret = cmd.cmd_write_register(4,ioDelayValue)
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x1)
    s.send(ret)
    sleep(0.1)
    # send ChIP_START
    ret = cmd.cmd_send_pulse(0x2)
    s.send(ret)
    sleep(0.3)
    # read Serdes Error
    ret = cmd.cmd_read_status(0) # read data
    s.send(ret)
    data = s.recv(4)
    serdesErr = data

    if ((serdesErr & 0x2) > 0):
        if (i==0):
            boundary = 1
        if (boundary == 1) & (ioDelayValue_ > 39)):
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
ret = cmd.cmd_send_pulse(0x1)
s.send(ret)
sleep(0.1)
# send ChIP_START
ret = cmd.cmd_send_pulse(0x2)
s.send(ret)
sleep(0.3)
# read Serdes Error
ret = cmd.cmd_read_status(0) # read data
s.send(ret)
data = s.recv(4)
serdesErr = data
print "Error = ", hex(serdesErr)

ftdIO.close_ftdi()
print "Finished ..."
exit()
