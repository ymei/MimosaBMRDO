from command import *
from i2c_control import *
import socket
import time
import sys
import os
import shlex

host = '192.168.2.3'
port = 1024
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host,port))

cmd = Cmd()

#s.setblocking(0)
if (len(sys.argv)==1):
    data_file_name = 'data'
    filesize_old = 2000000
elif (len(sys.argv)==2):
    data_file_name = str(sys.argv[1])
    filesize_old = 2000000
else :
    data_file_name = str(sys.argv[1])
    filesize_old = int(sys.argv[2])

data_file = data_file_name+'.sfs'
#fout = open(data_file,"a")

ret = cmd.cmd_send_pulse(0x2)
s.send(ret)

counter=0
while True :
    ret = cmd.cmd_read_datafifo(filesize_old)
    s.send(ret)
    toread = filesize_old*4
    buf = bytearray(toread)
    view = memoryview(buf)
    while toread:
        nbytes = s.recv_into(view, toread)
        view = view[nbytes:] # slicing views is cheap
        toread -= nbytes
    print "ok!"
#fout.write(data)
#time.sleep(1)
#fout.close
s.close()
