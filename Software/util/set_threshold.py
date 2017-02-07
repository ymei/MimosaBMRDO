from command import *
from i2c_control import *
import sys
import os
import shlex
import socket
import time
import numpy as np


# --read threshold from file--
thre = np.loadtxt('threshold.txt',dtype='i')

# --generate file for threshold seeting
f_write = open('thre_mem.txt','w')
# -- write instruction
f_write.write("0x0400000f\n")
# -- DAC 0~18
#0
f_write.write("0x17000064\n")
#1
f_write.write("0x1700000a\n")
#2
f_write.write("0x1700000a\n")
#3
f_write.write("0x1700000a\n")
#4
f_write.write("0x1700000a\n")
#5
f_write.write("0x17000028\n")
#6
f_write.write("0x17000020\n")
#7
f_write.write("0x17000080\n")
#8
f_write.write("0x17000064\n")
#9
f_write.write("0x17000032\n")
#10--ref1d
p_w  = thre[4] | 0x17000000
wr_data = "0x" + format(p_w,'x') + '\n'
f_write.write(wr_data)
# f_write.write("0x18000032\n")
#11--ref1c
p_w  = thre[3] | 0x17000000
wr_data = "0x" + format(p_w,'x') + '\n'
f_write.write(wr_data)
# f_write.write("0x1800006e\n")
#12--ref1b
p_w  = thre[2] | 0x17000000
wr_data = "0x" + format(p_w,'x') + '\n'
f_write.write(wr_data)
# f_write.write("0x1800007d\n")
#13--ref1a
p_w  = thre[1] | 0x17000000
wr_data = "0x" + format(p_w,'x') + '\n'
f_write.write(wr_data)
# f_write.write("0x1800006e\n")
#14--ref2
p_w  = thre[0] | 0x17000000
wr_data = "0x" + format(p_w,'x') + '\n'
f_write.write(wr_data)
# f_write.write("0x18000083\n")
#15
f_write.write("0x17000020\n")
#16
f_write.write("0x17000020\n")
#17
f_write.write("0x17000032\n")
#18
f_write.write("0xd300000a\n")

f_write.close()

s = socket.socket()
host = '127.0.0.1'
port = 1234
s.connect((host,port))
cmd = Cmd()
# --set jtag speed--
ret = cmd.cmd_write_register(3,0x4)
s.sendall(ret)
time.sleep(0.2)
ret = cmd.cmd_write_memory_file("thre_mem.txt")
s.sendall(ret)
time.sleep(0.2)
ret = cmd.cmd_send_pulse(0x8)
s.sendall(ret)
time.sleep(0.5)
# ret = cmd.cmd_send_pulse(0x2)
# s.sendall(ret)
# time.sleep(0.5)
s.close()
print "finished!!"
