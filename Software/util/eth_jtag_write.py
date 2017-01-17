from command import *
from i2c_control import *
import socket
import time

host = '192.168.2.3'
port = 1024
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host,port))

cmd = Cmd()

#ret = cmd.cmd_write_register(3,0x4)
#s.send(ret)
ret = cmd.cmd_write_memory_file("/home/wangdong/mapstest/JTAG_files/S1_L2.dat")
#ret = cmd.cmd_write_memory_file("wdtest.txt")
s.send(ret)
#time.sleep(2)
#ret = cmd.cmd_send_pulse(0x8)
#s.send(ret)
s.close()
#time.sleep(1)
