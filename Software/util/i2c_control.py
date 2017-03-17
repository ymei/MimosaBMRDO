from command import *
import socket
import time

###################################################
# functions for AD7993 control
###################################################
def i2c_ad7993_initial(s,cmd): # initial AD7993
# -- set configration reg to run on mode 2
    ret = cmd.cmd_write_register(0,0x2201) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0802) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
# -- set cycle timer reg to diable mode 3
    ret = cmd.cmd_write_register(0,0x2201) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0003) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    return 0

def i2c_ad7993_chipvdd_r(s,cmd): # read VDD for chips --channel 1
# -- start conversion
    ret = cmd.cmd_write_register(0,0x2200) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0010) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
# -- read conversion result reg
    ret = cmd.cmd_write_register(0,0x2205) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0000) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    ret = cmd.cmd_read_status(0) # read data
    s.send(ret)
    data = s.recv(4)
    print [hex(ord(w)) for w in data]
    time.sleep(0.2)
    return data

def i2c_ad7993_mimosavdd_r(s,cmd): # read VDD for chips --channel 2
# -- start conversion
    ret = cmd.cmd_write_register(0,0x2200) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0020) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
# -- read conversion result reg
    ret = cmd.cmd_write_register(0,0x2205) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0000) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    ret = cmd.cmd_read_status(0) # read data
    s.send(ret)
    data = s.recv(4)
    print [hex(ord(w)) for w in data]
    time.sleep(0.2)
    return data

def i2c_ad7993_ichip_r(s,cmd): # read VDD for chips --channel 3
# -- start conversion
    ret = cmd.cmd_write_register(0,0x2200) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0040) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
# -- read conversion result reg
    ret = cmd.cmd_write_register(0,0x2205) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0000) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    ret = cmd.cmd_read_status(0) # read data
    s.send(ret)
    data = s.recv(4)
    print [hex(ord(w)) for w in data]
    time.sleep(0.2)
    return data

def i2c_ad7993_imim_r(s,cmd): # read VDD for chips --channel 4
# -- start conversion
    ret = cmd.cmd_write_register(0,0x2200) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0080) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
# -- read conversion result reg
    ret = cmd.cmd_write_register(0,0x2205) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0000) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    ret = cmd.cmd_read_status(0) # read data
    s.send(ret)
    data = s.recv(4)
    print [hex(ord(w)) for w in data]
    time.sleep(0.2)
    return data

###################################################
# functions for AD7418 control
###################################################
def i2c_ad7418_initial(s,cmd): # initial AD7418
# -- set configration reg to run on shut down mode
    ret = cmd.cmd_write_register(0,0x2801) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0101) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
# -- set configration reg2 to run on sample by soft
    ret = cmd.cmd_write_register(0,0x2801) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0005) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    return 0

def i2c_ad7418_itself_tmp_r(s,cmd): # read tmperature from MIMOSA chips
# -- start conversion powerup and shutdown
    ret = cmd.cmd_write_register(0,0x2801) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0001) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.010)
    ret = cmd.cmd_write_register(0,0x2801) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0101) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
# -- read conversion result reg
    ret = cmd.cmd_write_register(0,0x2800) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0000) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    ret = cmd.cmd_write_register(0,0x2805) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0000) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    ret = cmd.cmd_read_status(0) # read data
    s.send(ret)
    data = s.recv(4)
    print [hex(ord(w)) for w in data]
    time.sleep(0.2)
    return data

def i2c_ad7418_mimosa_tmp_r(s,cmd): # read tmperature from ad7418 itself
# -- start conversion powerup and shutdown
    ret = cmd.cmd_write_register(0,0x2801) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x8001) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    ret = cmd.cmd_write_register(0,0x2801) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x8101) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
# -- read conversion result reg
    ret = cmd.cmd_write_register(0,0x2800) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0004) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    ret = cmd.cmd_write_register(0,0x2805) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0000) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    ret = cmd.cmd_read_status(0) # read data
    s.send(ret)
    data = s.recv(4)
    print [hex(ord(w)) for w in data]
    time.sleep(0.2)
    return data

###################################################
# functions for AD5252 control
###################################################
def i2c_ad5252_pot_chip(s,cmd,data): # set pot for chip power
# -- set EEMEM value for RDAC1
    ret = cmd.cmd_write_register(0,0x2C01) # set slave address,mode,wr
    s.send(ret)
    sdata = data<<8 | 0x21
    ret = cmd.cmd_write_register(1,sdata) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
# -- restore EEMEM to RDC
    ret = cmd.cmd_write_register(0,0x2C00) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x00b8) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
# -- set NOP command
    ret = cmd.cmd_write_register(0,0x2C00) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0080) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    return 0

def i2c_ad5252_pot_mimosa(s,cmd,data): # set pot for mimosa power
# -- set EEMEM value for RDAC3
    ret = cmd.cmd_write_register(0,0x2C01) # set slave address,mode,wr
    s.send(ret)
    sdata = data<<8 | 0x23
    ret = cmd.cmd_write_register(1,sdata) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
# -- restore EEMEM to RDC
    ret = cmd.cmd_write_register(0,0x2C00) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x00b8) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
# -- set NOP command
    ret = cmd.cmd_write_register(0,0x2C00) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0080) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    return 0

###################################################
# functions for LTC2635 control
###################################################
def i2c_ltc2635_thre_vchip(s,cmd,data): # set DAC out for threshold of thre_vchip
    ret = cmd.cmd_write_register(0,0x4102) # set slave address,mode,wr
    s.send(ret)
    sdata = ((data>>4)<<8) | 0x30
    ret = cmd.cmd_write_register(1,sdata) # set write address and write data0
    s.send(ret)
    sdata = (data & 0xf)<<4
    ret = cmd.cmd_write_register(2,sdata) # set write address and write data1
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    return 0

def i2c_ltc2635_thre_vmim(s,cmd,data): # set DAC out for threshold of thre_vmim
    ret = cmd.cmd_write_register(0,0x4102) # set slave address,mode,wr
    s.send(ret)
    sdata = ((data>>4)<<8) | 0x31
    ret = cmd.cmd_write_register(1,sdata) # set write address and write data0
    s.send(ret)
    sdata = (data & 0xf)<<4
    ret = cmd.cmd_write_register(2,sdata) # set write address and write data1
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    return 0

###################################################
# functions for PCF8574 control
###################################################
def i2c_pcf8574_reset_latchup(s,cmd): # reset latchup of PCF8574
# -- set LV_vchip and LV_vmim to 0
    ret = cmd.cmd_write_register(0,0x2100) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0000) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
# -- set LV_vchip and LV_vmim back to 1
    time.sleep(0.2)
    ret = cmd.cmd_write_register(0,0x2100) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x00ff) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    return 0

def i2c_pcf8574_read_latchup(s,cmd): # reset latchup of PCF8574
    ret = cmd.cmd_write_register(0,0x2104) # set slave address,mode,wr
    s.send(ret)
    ret = cmd.cmd_write_register(1,0x0000) # set write address and write data0
    s.send(ret)
    ret = cmd.cmd_send_pulse(0x10) # start
    s.send(ret)
    time.sleep(0.2)
    ret = cmd.cmd_read_status(0) # read data
    s.send(ret)
    data = s.recv(4)
    print [hex(ord(w)) for w in data]
    time.sleep(0.2)
    return data

if __name__ == "__main__":
    host = '192.168.2.3'
    port = 1024
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((host,port))
    cmd = Cmd()
    data = i2c_ad7993_chipvdd_r(s,cmd)
    s.close()
