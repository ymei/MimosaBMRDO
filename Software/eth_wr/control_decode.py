#!/usr/bin/python
import eth_control_fun as ethc
import socket               # Import socket module

s = socket.socket()         # Create a socket object
host = '192.168.2.3'
port = 1024                # Reserve a port for your service.
s.connect((host, port))

str_send = ethc.eth_control_reg_write(0,0x0001)
print str_send
s.send(str_send)
str_send = ethc.eth_control_reg_read(0)
print str_send
s.send(str_send)
print s.recv(14)

s.close                     # Close the socket when done
