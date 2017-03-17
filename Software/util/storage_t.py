import numpy
import time
from multiprocessing import Value, Array
import numpy as np
import os
import sys

class Storage():
    # def __init__(self):
    def run(self, lock, lock_data, data, num_now, stop):
        # -- MAPS map for display
        os.system("rm -rf /ssdone/data.txt")
        f_write = open('/ssdone/data.txt','wb+')

        # with lock :
        #     readnum = num_now.value
        readnum = 0
        while stop.value==1 :
            with lock :
                num = num_now.value

            if num == readnum :
                continue

            mapsbyte = np.ctypeslib.as_array(data[readnum].get_obj())
            # with lock_data:
            f_write.write(mapsbyte)

            if num > readnum :
                gap = num - readnum
            else :
                gap = num + 128 - readnum

            if gap > 20 :
                print "read slow"

            if readnum == 127:
                readnum = 0
            else :
                readnum += 1

        f_write.close()
        print "storage process terminate"
