from command import *
import socket

host = '192.168.2.3'
port = 1024
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host,port))
#s.setblocking(1)
cmd = Cmd()
ret = cmd.cmd_write_register()
#ret = cmd.cmd_read_register(0)
print [hex(ord(w)) for w in ret]
#s.send(ret)
#data = s.recv(4)
#print [hex(ord(s)) for w in data]
s.close()
