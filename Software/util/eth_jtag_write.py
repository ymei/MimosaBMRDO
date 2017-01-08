from command import *
from i2c_control import *
import socket
import time

host = '192.168.2.3'
port = 1024
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host,port))

cmd = Cmd()

# -- set threshold
i2c_ltc2635_thre_vchip(s,cmd,0x5ff)
i2c_ltc2635_thre_vmim(s,cmd,0x5ff)
# -- reset latchup
i2c_pcf8574_reset_latchup(s,cmd)
i2c_pcf8574_read_latchup(s,cmd)
# -- read temperature
time.sleep(0.1)
i2c_pcf8574_read_latchup(s,cmd)

time.sleep(1)
#s.setblocking(1)
ret = cmd.cmd_write_register(3,0x4)
s.send(ret)
#time.sleep(10)
# ret = cmd.cmd_write_memory_file("S1_L2.dat")
ret = cmd.cmd_write_memory_file("wdtest.txt")
s.send(ret)
time.sleep(1)
#ret = cmd.cmd_write_register(3,4)
#s.send(ret)
ret = cmd.cmd_send_pulse(0xc)
#print [hex(ord(w)) for w in ret]
s.send(ret)
#time.sleep(1)
ret = cmd.cmd_send_pulse(0x8)
s.send(ret)
#s.send(ret)
#s.send(ret)
time.sleep(1)
#s.send(ret)
#time.sleep(1)
ret = cmd.cmd_read_memory(0,6)
s.send(ret)
data = s.recv(24)
print [hex(ord(w)) for w in data]
s.close()
