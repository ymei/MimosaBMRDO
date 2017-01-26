from command import *
import socket
import time
import select

class RecvWorker():
    def __init__(self):
        self._running = True

    def terminate(self):
        self._running = False

    def run(self, sock, lock, sign, fifo):
        sock.settimeout(3)
        while self._running:
            try:
                toread = 1024000
                data = ""
                while(toread):
#                    print sign
                    tmp = sock.recv(toread)
                    nbytes = len(tmp)
                    toread -= nbytes
                    data += tmp
                if (not fifo.full()) :
                    fifo.put(data)
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

        ret = self._cmd.cmd_read_datafifo(256000)
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
                        sn = sock.send(sdata)
                        if sn != cnt :
                            print sn
                        ctmp = ctmp - sn
