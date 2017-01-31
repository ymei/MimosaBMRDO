from command import *
import socket
import time
import select

datanum = 200000
class RecvWorker():
    def __init__(self):
        self._running = True
        self._buf = bytearray(datanum*4*128)
        self._seqnum = 0

    def terminate(self):
        self._running = False

    def get_buf_num(self,lock):
        with lock :
            number = self.seqnum
        return number

    def read_buf(self,num):
        data = buf[(datanum*4*num):(datanum*4*(num+1))]
        return data

    def run(self, sock, lock, sign):
        sock.settimeout(3)
        while self._running:
            try:
                with lock:
                    if self.seqnum == 1023 :
                        self.seqnum = 0
                    else :
                        self.seqnum += 1
                toread = datanum*4
                view = memoryview(buf[(datanum*4*self.seqnum):(datanum*4*(self.seqnum+1))])
                while toread:
                    nbytes = sock.recv_into(view, toread)
                    view = view[nbytes:] # slicing views is cheap
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
        while self._running:
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
