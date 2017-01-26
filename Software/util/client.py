# -*- coding: utf-8 -*-
"""
Created on Wed Jan 18 13:16:54 2017

Client for Socket Communication.
@author: Dong Wang
"""
from command import *
from i2c_control import *
import sys
import os
import shlex
import socket
import time
import select
from threading import Thread
from multiprocessing import Process, Manager, Lock
from multiprocessing import Value, Array

class RecvWorker():
    def __init__(self):
        self._running = True

    def terminate(self):
        self._running = False

    def run(self, sock, lock, sign):
        sock.settimeout(3)
        i = 0
        buf = bytearray(10240000)

        while self._running:
            i += 1
            print i
            try:
                toread = 10240000
                # view = memoryview(buf)
                # while toread:
                #     nbytes = sock.recv_into(view, toread)
                #     view = view[nbytes:] # slicing views is cheap
                #     toread -= nbytes
                while(toread):
#                    print sign
                    tmp = s.recv(toread)
                    nbytes = len(tmp)
                    toread -= nbytes
                with lock :
                    sign.value = 1
                continue
            except socket.timeout:
                print("RecvWorker:socket timeout")
                self.terminate()
        print "recv terminate"


class SendWorker():
    def __init__(self):
        self._running = True
        self._cmd = Cmd()

    def terminate(self):
        self._running = False

    def run(self, sock, lock, sign):
        ret = self._cmd.cmd_send_pulse(0x2)
        cnt = len(ret)
        ctmp = cnt
        while ctmp :
            readable , writable , exceptional = select.select([],[sock],[],2)
            for s in writable :
                sdata = ret[cnt-ctmp:cnt]
                sn = s.send(sdata)
                if sn != cnt :
                    print sn
                ctmp = ctmp - sn

        ret = self._cmd.cmd_read_datafifo(2560000)
        cnt = len(ret)
        ctmp = cnt
        while ctmp :
            readable , writable , exceptional = select.select([],[sock],[],2)
            for s in writable :
                sdata = ret[cnt-ctmp:cnt]
                sn = s.send(sdata)
                if sn != cnt :
                    print sn
                ctmp = ctmp - sn

        while self._running:
#        for i in range(3000):
#            print sign.value
            if sign.value == 1 :
                with lock:
                    sign.value = 0
                ctmp = cnt
                while ctmp :
                    readable , writable , exceptional = select.select([],[sock],[],2)
                    for s in writable :
                        sdata = ret[cnt-ctmp:cnt]
                        sn = s.send(sdata)
                        if sn != cnt :
                            print sn
                        ctmp = ctmp - sn
#        print "sender terminate"

lock = Lock()
sign = Value('d', 1)
s = socket.socket()

#host = socket.gethostname()
host = '192.168.2.3'
port = 1024

s.connect((host,port))
sender = SendWorker()
recver = RecvWorker()
t_sender = Thread(target=sender.run, args=(s,lock,sign))
t_recver = Thread(target=recver.run, args=(s,lock,sign))
t_sender.start()
t_recver.start()

time.sleep(10)
if t_sender.is_alive():
    print "term send s"
    sender.terminate()
    time.sleep(2)
    t_sender.join()
    print "term send end"
time.sleep(2)
if t_recver.is_alive():
    print "term rec s"
    recver.terminate()
    time.sleep(2)
    t_recver.join()
    print "tern rec end"
s.close()
