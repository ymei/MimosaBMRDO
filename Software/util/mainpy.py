# -*- coding: utf-8 -*-
"""
Created on Wed Jan 20 2017
This the main python script for datataking and processing
@author: Dong Wang
"""
from ethernet_t import *
from dataprocess_t import *
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

class Disper():
    def __init__(self):
        self._running = True

    def terminate(self):
        self._running = False

    def run(self, q_pro_dis, lock):
        while self._running :
            # -- display processing
            fig = pyplot.figure()
            maps = numpy.zeros(shape=(928,960))
            cmap = mpl.colors.ListedColormap(['white','red'])
            bounds=[0,0.5,1]
            norm = mpl.colors.BoundaryNorm(bounds, cmap.N)
            img = pyplot.imshow(maps,interpolation='nearest',cmap = cmap,norm=norm)
            pyplot.colorbar(img,cmap=cmap,norm=norm,boundaries=bounds,ticks=[0,0.5,1])
            def update(*args) :
                global q_pro_dis
                with lock :
                    check = not q_pro_dis.empty()
                if check :
                    with lock :
                        data_dis = q_pro_dis.get()
                    img.set_data(data_dis)
                return img
            anim = animation.FuncAnimation(fig, update, interval=100)
            pyplot.show()



# -- define fifo --
# -- fifo between ethernet readout to dataprocessing unit
q_the_pro = Queue()
# -- fifo between dataprocessing unit to display unit
q_pro_dis = Queue()

# -- frame counter
fcount=Value('d', 0)

# -- ethernet processing thread
lock = Lock()
sign = Value('d', 1)
s = socket.socket()
host = '192.168.2.3'
port = 1024
s.connect((host,port))

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
s.sendall(ret)
time.sleep(0.2)
ret = cmd.cmd_send_pulse(0x8)
s.sendall(ret)
time.sleep(0.5)

# -- disp data take processing
disper = Disper()
t_disper = Process(target=disper.run, args=(q_pro_dis,lock))
t_disper.start()
# -- data processing Thread
dataprocesser = Dataprocess()
t_dataprocesser = Process(target=dataprocesser.run, args=(q_the_pro,q_pro_dis,fcount,lock))
t_dataprocesser.start()
# -- start ethernet thread
sender = SendWorker()
recver = RecvWorker()
t_sender = Process(target=sender.run, args=(s,lock,sign))
t_recver = Process(target=recver.run, args=(s,lock,sign,q_the_pro))
t_recver.start()
t_sender.start()

# for i in range(600):
# #while True :
#     time.sleep(0.1)
#     if (not q_pro_dis.empty()) :
#         maps = q_pro_dis.get()
#         # img = pyplot.imshow(maps,interpolation='nearest',cmap = cmap,norm=norm)
#         # pyplot.pause(0.1)

# -- Thread ending --
time.sleep(30)
if t_dataprocesser.is_alive():
    dataprocesser.terminate()
    t_dataprocesser.join()
if t_sender.is_alive():
    sender.terminate()
    time.sleep(1)
    t_sender.join()
time.sleep(4)
if t_recver.is_alive():
    recver.terminate()
    time.sleep(1)
    t_recver.join()
if t_disper.is_alive():
    disper.terminate()
    t_disper.join()
s.close()
