from command import *
import socket
import time
import select
import multiprocessing
from multiprocessing import Value, Array
import numpy as np

datanum = 2000000
buffernum = 128
class RecvWorker():
    # def __init__(self):
    def run(self, sock, lock, sign, data, num_now, stop):
        sock.settimeout(3)
        # self._shared_array_base = multiprocessing.Array('B', datanum*4*buffernum)
        view_list = []
        for i in range(buffernum) :
            view_list.append( memoryview(np.ctypeslib.as_array(data[i].get_obj())) )
        while stop.value==1 :
            try:
                with lock:
                    if num_now.value == (buffernum-1) :
                        num_now.value = 0
                        nseq = num_now.value
                    else :
                        num_now.value += 1
                        nseq = num_now.value
                toread = datanum*4
                view_tmp = view_list[nseq]
                while toread:
                    nbytes = sock.recv_into(view_tmp, toread)
                    view_tmp = view_tmp[nbytes:] # slicing views is cheap
                    toread -= nbytes
                with lock :
                    sign.value = 1
                continue
            except socket.timeout:
                print("RecvWorker:socket timeout")
                with lock :
                    stop.value = 0
        print "recv terminate"


class SendWorker():
    def __init__(self):
        self._cmd = Cmd()
    def run(self, sock, lock, sign, fifo, stop):
        ret = self._cmd.cmd_read_datafifo(datanum)
        with lock :
            fifo.put(ret)
        ret = self._cmd.cmd_send_pulse(0x2)
        with lock :
            fifo.put(ret)
        ret = self._cmd.cmd_read_datafifo(datanum)
        with lock :
            fifo.put(ret)

        while stop.value == 1:
            if sign.value == 1 :
                ret = self._cmd.cmd_read_datafifo(datanum)
                with lock :
                    fifo.put(ret)
                with lock:
                    sign.value = 0
            while not fifo.empty() :
                with lock:
                    sdata = fifo.get()
                sock.sendall(sdata)
        print "send terminate"

class CmdServer():
    def __init__(self):
        self._cmd = Cmd()
    def run(self, lock, fifo, stop):
        s = socket.socket()
        host = '127.0.0.1'
        port = 1234
        s.bind((host,port))

        while stop.value == 1:
            try :
                s.settimeout(0.2)
                s.listen(1)
                c,addr = s.accept()
                while stop.value == 1:
                    edata = ""
                    num = 0
                    while (num%4 != 0) or (num == 0) :
                        tdata = c.recv(1024)
                        if not tdata :
                            break
                        counter = len(tdata)
                        num += counter
                        edata += tdata
                    if not tdata :
                        break
                    fifo.put(edata)
                c.close()
            except socket.timeout :
                continue
        s.close()
        print "CmdServer terminate"
