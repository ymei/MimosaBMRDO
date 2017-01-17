from command import *
from i2c_control import *
import socket
import time
import sys
import os
import shlex

# -- setting network
host = '192.168.2.3'
port = 1024
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host,port))
cmd = Cmd()
s.setblocking(1)
data_path = '/home/wangdong/mapstest/data/'
if (len(sys.argv)==1):
    data_file_name = 'data'
    filesize_old = 2000000
elif (len(sys.argv)==2):
    data_file_name = str(sys.argv[1])
    filesize_old = 2000000
else :
    data_file_name = str(sys.argv[1])
    filesize_old = int(sys.argv[2])

data_file = data_path+data_file_name+'.sfs'
fout = open(data_file,"a")

# write to JTAG
ret = cmd.cmd_write_register(3,0x4)
s.send(ret)
ret = cmd.cmd_write_memory_file("/home/wangdong/mapstest/JTAG_files/S1_L2.dat")
#ret = cmd.cmd_write_memory_file("S1_L2.dat")
s.send(ret)
time.sleep(0.2)
ret = cmd.cmd_send_pulse(0x8)
s.send(ret)
time.sleep(0.5)
# -- set to readout
ret = cmd.cmd_send_pulse(0x2)
s.send(ret)
ret = cmd.cmd_read_datafifo(filesize_old)
s.send(ret)
data = s.recv(filesize_old*4)
#print [hex(ord(w)) for w in data]
fout.write(data)
time.sleep(1)
fout.close
s.close()

