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
    def run(self, sock, lock, sign, stop):
        ret = self._cmd.cmd_read_datafifo(datanum)
        cnt = len(ret)
        ctmp = cnt
        while ctmp :
            readable , writable , exceptional = select.select([],[sock],[],2)
            for s in writable :
                sdata = ret[cnt-ctmp:cnt]
                sn = sock.send(sdata)
                if sn != cnt :
                    print sn
                ctmp = ctmp - sn

        ret = self._cmd.cmd_send_pulse(0x2)
        cnt = len(ret)
        ctmp = cnt
        while ctmp :
            readable , writable , exceptional = select.select([],[sock],[],2)
            for s in writable :
                sdata = ret[cnt-ctmp:cnt]
                sn = sock.send(sdata)
                if sn != cnt :
                    print sn
                ctmp = ctmp - sn

        ret = self._cmd.cmd_read_datafifo(datanum)
        cnt = len(ret)
        ctmp = cnt
        while ctmp :
            readable , writable , exceptional = select.select([],[sock],[],2)
            for s in writable :
                sdata = ret[cnt-ctmp:cnt]
                sn = sock.send(sdata)
                if sn != cnt :
                    print sn
                ctmp = ctmp - sn
        i = 0
        while stop.value == 1:
#        for i in range(3000):
#            print sign.value
            if sign.value == 1 :
                i +=1
#                print "input :", i
                with lock:
                    sign.value = 0
                ctmp = cnt
                while ctmp :
                    readable , writable , exceptional = select.select([],[sock],[],2)
                    for s in writable :
                        sdata = ret[cnt-ctmp:cnt]
                        sn = sock.send(sdata)
                        if sn != cnt :
                            print sn
                        ctmp = ctmp - sn
        print "send terminate"
