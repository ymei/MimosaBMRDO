from command import *
import socket
import time
import select

datanum = 20000000
class RecvWorker():
    def __init__(self):
        self._running = True

    def terminate(self):
        self._running = False

    def run(self, sock, lock, sign, fifo):
        sock.settimeout(3)
        buf = bytearray(datanum*4)
        while self._running:
            try:
                toread = datanum*4
                view = memoryview(buf)
                while toread:
                    nbytes = sock.recv_into(view, toread)
                    view = view[nbytes:] # slicing views is cheap
                    toread -= nbytes
                if (not fifo.full()) :
                    fifo.put(buf)
                else :
                    print "fifo full"
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
                print "input :", i
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
