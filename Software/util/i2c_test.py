from i2c_control import *
import socket
import time

# -- setting network
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
print "latch up status : "
i2c_pcf8574_read_latchup(s,cmd)
i2c_ad7418_initial(s,cmd)
print "mimosa temp : "
i2c_ad7418_mimosa_tmp_r(s,cmd)
print "chip temp : "
i2c_ad7418_itself_tmp_r(s,cmd)
# -- ad7997 test
i2c_ad7993_initial(s,cmd)
i2c_ad7993_chipvdd_r(s,cmd)
s.close()
