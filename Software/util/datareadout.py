from command import *
from i2c_control import *
import socket
import time

# -- setting network
host = '192.168.2.3'
port = 1024
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host,port))
cmd = Cmd()

# -- set start
ret = cmd.cmd_send_pulse(0x2)
s.send(ret)

s.close()
