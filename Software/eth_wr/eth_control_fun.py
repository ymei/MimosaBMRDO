#!/usr/bin/python
def eth_control_reg_write(addr,data):
    if addr < 0 or addr > 31 :
        print "address exceed 0~31!"
    else :
        str = ((addr+32)<<16) + data
        return "00%06x"%(str)

def eth_control_reg_read(addr):
    if addr < 0 or addr > 31 :
        print "address exceed 0~31!"
    else :
        str = ((addr+32)<<16)
        return "80%06x"%(str)

def eth_status_reg( str ):
   print str;
   return;

def eth_pulse_reg( str ):
   print str;
   return;
