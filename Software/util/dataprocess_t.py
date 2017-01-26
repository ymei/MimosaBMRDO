import numpy
class Dataprocess():
    def __init__(self):
        self._running = True
        self._header = 0xaaaa
        self._tailer = 0x5678
        self._counter = 0
        self._row = 0
        self._column = 0
        self._code = 0
        self._odd = True
        self._hsign = 0
        self._tsign = 0
        self._pdata = 0x0000
        self._odd = False
    def terminate(self):
        self._running = False

    def run(self, fifo, fifomaps, fcount):
        # -- MAPS map for display
        maps = numpy.zeros(shape=(928,960))
        fcount.value = 0
        w4 = 0
        w3 = 0
        w2 = 0
        w1 = 0
        pdata_pre2 = 0
        pdata_pre1 = 0
        while self._running:
            if (not fifo.empty()) :
                data = fifo.get()
                for w in data :
                    w4 = w3
                    w3 = w2
                    w2 = w1
                    w1 = ord(w)
                    if self._counter != 0 :
                        if self._odd :
                            self._pdata = ord(w)
                            self._odd = False
                        else :
                            self._pdata = self._pdata + ((ord(w)) << 8)
                            self._odd = True
                            pdata_pre2 = pdata_pre1
                            pdata_pre1 = self._pdata
                    #        if self._pdata!=0 :
                    #            print hex(self._pdata)
                            self._counter += 1
                            if self._pdata == self._tailer :
                                if self._tsign == 0 :
                                    self._tsign = 1
                                else :
                                    self._counter = 0
                                    self._tsign = 0
                                    fcount.value += 1
                                    if (fcount.value%1000) == 0 :
                                        fifomaps.put(maps)
                                        maps = numpy.zeros(shape=(928,960))
                            else :
                                self._tsign = 0
                            if self._counter > 6 :
                                if (pdata_pre2 & 0x1000) != 0 :
                                    self._row = (pdata_pre2 >>2) & 0x03ff
                                else :
                                    self._column = (pdata_pre2 >>2) & 0x03ff
                                    self._code = pdata_pre2 & 0x0003
                                    if(self._column+self._code<960)&(self._row<928):
                                        maps[self._row, self._column:(self._column+self._code+1)] += 1
                                    # else :
                                    #     print "row: ",self._row
                                    #     print "colum: ",self._column
                    else :
                        self._odd = True
                        if (w1==0xaa)&(w2==0xaa)&(w3==0xaa)&(w4==0xaa) :
                            self._counter = 1
