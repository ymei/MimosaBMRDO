#!/usr/bin/python           # This is client.py file

import socket               # Import socket module

s = socket.socket()         # Create a socket object
host = '192.168.2.3'
port = 1024                # Reserve a port for your service.

s.connect((host, port))
s.send('aaaaaaaabbbbbb')
print s.recv(14)
s.close                     # Close the socket when done
