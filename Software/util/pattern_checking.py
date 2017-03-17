# -*- coding: utf-8 -*-
"""
Created on Wed Jan 20 2017
This the main python script for datataking and processing
@author: Dong Wang
"""
from storage_t import *
from daq_t import *
from datap_t import *
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
from multiprocessing import Queue
import numpy
from matplotlib import pyplot
import matplotlib as mpl
import matplotlib.animation as animation
from matplotlib.colors import LogNorm

class Disper():
    def run(self, q_pro_dis, lock, stop):
        mapsbyte = np.ctypeslib.as_array(q_pro_dis.get_obj())
        mapsdis = mapsbyte.reshape(928,960)
        maps = numpy.zeros(shape=(928,960))
        fig = pyplot.figure()
        img = pyplot.imshow(maps, cmap='viridis',norm=LogNorm(vmin=1, vmax=100))
        pyplot.colorbar(img, orientation='vertical')
        while stop.value==1 :
            # -- display processing
            def update(*args) :
                global q_pro_dis
                with lock :
                    img.set_data(mapsdis)
                return img
            anim = animation.FuncAnimation(fig, update, interval=50)
            pyplot.show()
        print "display terminate"

# -- ethernet processing thread
lock_dis = Lock()
lock_value = Lock()
lock_data = Lock()
sign = Value('i', 0)
s = socket.socket()
host = '192.168.2.3'
port = 1024
s.connect((host,port))

cmdfifo = Queue()
datanum = 200000
buffernum = 128
# cdata = Array('B', datanum*4)
# data = Array(cdata, buffernum)
data = []
for i in range(buffernum) :
    data.append(Array('B', datanum*4))
q_pro_dis = Array('H', 928*960)
num_now=Value('i',0)
num_read=Value('i',0)
pulse=Value('i',0)
# -- MAPS board initial
cmd = Cmd()
# -- set threshold
i2c_ltc2635_thre_vchip(s,cmd,0x5ff)
i2c_ltc2635_thre_vmim(s,cmd,0x5ff)
time.sleep(0.3)
# -- reset latchup
i2c_pcf8574_reset_latchup(s,cmd)
i2c_pcf8574_read_latchup(s,cmd)
time.sleep(1)

# write to JTAG
ret = cmd.cmd_write_register(3,0x4)
s.sendall(ret)
#ret = cmd.cmd_write_memory_file("/home/wangdong/mapstest/JTAG_files/S1_L2.dat")
ret = cmd.cmd_write_memory_file("S1_L2.dat")
# ret = cmd.cmd_write_memory_file("pattern_mem.txt")
s.sendall(ret)
time.sleep(0.2)
ret = cmd.cmd_send_pulse(0x8)
s.sendall(ret)
time.sleep(0.5)

ret = cmd.cmd_write_memory_file("pattern_mem.txt")
s.sendall(ret)
time.sleep(0.2)
ret = cmd.cmd_send_pulse(0x8)
s.sendall(ret)
time.sleep(0.5)

# -- write iodelay
# load IOdelay values
ret = cmd.cmd_write_register(4,0x3b3b)
s.sendall(ret)
time.sleep(0.1)
ret = cmd.cmd_send_pulse(0x1)
s.sendall(ret)

# # -- disp data take processing
# stopdis=Value('i',1)
# disper = Disper()
# t_disper = Process(target=disper.run, args=(q_pro_dis,lock_dis,stopdis))
# t_disper.start()
# -- storage processing
stopstore=Value('i',1)
storage = Storage()
t_storage = Process(target=storage.run, args=(lock_value, lock_data, data, num_now, stopstore))
t_storage.start()

# -- start ethernet thread
stoprecv=Value('i',1)
stopsend=Value('i',1)
stopserver=Value('i',1)
sender = SendWorker()
recver = RecvWorker()
server = CmdServer()
t_sender = Process(target=sender.run, args=(s, lock_value, sign, cmdfifo, stopsend))
t_recver = Process(target=recver.run, args=(s, lock_value, lock_data, sign, data, num_now, stoprecv))
t_server = Process(target=server.run, args=(lock_value, cmdfifo, stopserver))
t_recver.start()
t_sender.start()
t_server.start()
# # -- data processing Thread
# stopproc=Value('i',1)
# dataprocesser = Dataprocess()
# t_dataprocesser = Process(target=dataprocesser.run, args=(q_pro_dis, lock_value, lock_dis, data, num_now, stopproc))
# t_dataprocesser.start()



# -- Thread ending --
# for tt in range(10):
#     time.sleep(3600)
time.sleep(10)

if t_storage.is_alive():
    stopstore.value = 0
    t_storage.join()
# if t_dataprocesser.is_alive():
#     stopproc.value = 0
#     t_dataprocesser.join()
if t_server.is_alive():
    stopserver.value = 0
    t_server.join()
if t_sender.is_alive():
    stopsend.value = 0
    t_sender.join()
time.sleep(6)
if t_recver.is_alive():
    stoprecv.value = 0
    t_recver.join()
# if t_disper.is_alive():
#     stopdis.value = 0
#     t_disper.join()

s.close()
