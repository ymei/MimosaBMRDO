from command import *
import numpy
import time
from multiprocessing import Value, Array
import numpy as np
import copy
from ctypes import *

class Dataprocess():
    def __init__(self):
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

    def run(self, fifomaps, fifomaps_temp, lock, lock_dis, lock_data, data, num_now, stop):
        # -- MAPS map for display
        mapsbyte_temp = np.ctypeslib.as_array(fifomaps_temp.get_obj())
        addr_mapsbyte_temp, flag = mapsbyte_temp.__array_interface__['data']
        w4 = 0
        w3 = 0
        w2 = 0
        w1 = 0
        pdata_pre2 = 0
        pdata_pre1 = 0
        mapsbyte = np.ctypeslib.as_array(fifomaps.get_obj())
        addr_mapsbyte, flag = mapsbyte.__array_interface__['data']
        # q_pro_dis = mapsbyte.reshape(928,960)
        fcounter = c_int(0)
        muskmap = np.loadtxt('wdtest.txt','int')
        muskmap_addr, flag = muskmap.__array_interface__['data']
        num_pre = 0
        while stop.value==1 :
            with lock :
                num = num_now.value
            # with lock_data :
            # data_tmp = np.copy(data[(num+125)%128])
            # data_tmp = data[num]
            # data_tmp = data[(num+124)%128]
            if num == num_pre :
                continue
            data_tmp = np.ctypeslib.as_array(data[(num+124)%128].get_obj())
            addr_data,flag = data_tmp.__array_interface__['data']
            data_calculate(addr_data,addr_mapsbyte,addr_mapsbyte_temp,muskmap_addr,fcounter,5000)
            num_pre = num
            # fcounter = 0
            # for w in data_tmp :
            #     w4 = w3
            #     w3 = w2
            #     w2 = w1
            #     w1 = w
            #     if self._counter != 0 :
            #         if self._odd :
            #             self._pdata = w
            #             self._odd = False
            #         else :
            #             self._pdata = self._pdata + (w << 8)
            #             self._odd = True
            #             pdata_pre2 = pdata_pre1
            #             pdata_pre1 = self._pdata
            #             self._counter += 1
            #             if self._pdata == self._tailer :
            #                 if self._tsign == 0 :
            #                     self._tsign = 1
            #                 else :
            #                     self._counter = 0
            #                     self._tsign = 0
            #                     fcounter +=1
            #                     # print fcounter
            #                     q_pro_dis[:] = maps
            #                     if fcounter == 1000 :
            #                         # with lock_dis:
            #                         #     for i in range(len(maps)) :
            #                         #         for j in range(len(maps[i])) :
            #                         #             if muskmap[i][j] == 0 :
            #                         #                 q_pro_dis[i][j] = maps[i][j]
            #                         #             else :
            #                         #                 q_pro_dis[i][j] = 0
            #                         # q_pro_dis[:] = maps
            #                         maps = numpy.zeros(shape=(928,960))
            #                         fcounter = 0
            #                         # break
            #             else :
            #                 self._tsign = 0
            #             # if self._counter > 2 :  # -- without counter
            #             if self._counter > 4 :  # -- withcounter
            #                 if (pdata_pre2 & 0x1000) != 0 :
            #                     self._row = (pdata_pre2 >>2) & 0x03ff
            #                 else :
            #                     self._column = (pdata_pre2 >>2) & 0x03ff
            #                     self._code = pdata_pre2 & 0x0003
            #                     if(self._column+self._code<960)&(self._row<928):
            #                         maps[self._row, self._column:(self._column+self._code+1)] += 1
            #                     # else :
            #                     #     print "row: ",self._row
            #                     #     print "colum: ",self._column
            #     else :
            #         self._odd = True
            #         if (w1==0xaa)&(w2==0xaa)&(w3==0xaa)&(w4==0xaa) :
            #             self._counter = 1
            # time.sleep(0.3)
        print "data process terminate"
