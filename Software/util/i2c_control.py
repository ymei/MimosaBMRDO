#i2c_ena       <= config_reg(0);                 -- config_reg 0*16
#i2c_mode      <= config_reg(16);                -- config_reg 1*16
#i2c_rw        <= config_reg(17);
#i2c_addr      <= config_reg(30 downto 24);
#i2c_wr_addr   <= config_reg(39 downto 32);      -- config_reg 2*16
#i2c_wr_data   <= config_reg(47 downto 40);
#status_reg(7 downto 0)   <= i2c_rd_data0;                   --status_reg 0*16
#status_reg(15 downto 8)  <= i2c_rd_data1;

from command import *
import socket

def i2c_read_ad7993(s,cmd,addr):
    ret = cmd.cmd_send_pulse(0x10) # i2c reset
    s.send(ret)
    #ret = cmd.cmd_write_register(0,0x0) # start -> 0
    #s.send(ret)
    ret = cmd.cmd_write_register(1,0x2200) # set slave address
    s.send(ret)
    ret = cmd.cmd_write_register(2,addr) # set write address and write data
    s.send(ret)
    #ret = cmd.cmd_write_register(0,0x1) # start -> 1
    #s.send(ret)
    #ret = cmd.cmd_write_register(0,0x1) # start -> 0
    #s.send(ret)
    ret = cmd.cmd_send_pulse(0x20) # start
    s.send(ret)
    ret = cmd.cmd_read_status(0) # read
    s.send(ret)
    data = s.recv(4)
    print [hex(ord(w)) for w in data]
    return data

if __name__ == "__main__":
    host = '192.168.2.3'
    port = 1024
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((host,port))
    #s.setblocking(1)
    cmd = Cmd()
    data = i2c_read_ad7993(s,cmd,0x2)
    #ret = cmd.cmd_read_register(0)
    #print [hex(ord(w)) for w in ret]
    #s.send(ret)
    #data = s.recv(4)
    #print [hex(ord(s)) for w in data]
    s.close()
