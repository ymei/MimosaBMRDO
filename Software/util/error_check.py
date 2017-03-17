import numpy as np
import struct

fname =  open("/ssdone/data.txt",'rb+')

con_er = 0

sign = 0
counter = 0xffff
data_pre = 0
cd1=0
con_d = 0
for j in range(1) :
    for i in range(50000000) :
        data = struct.unpack('H', fname.read(2))
        # print hex(data[0])
        if data[0] == 0xaaaa :
            counter = 0x3000
            con_d = 0
        if counter!=0xffff:
            if data[0] == 0xaaaa :
                counter = 0x3000
                sign = 0
                con_d = 0
            elif con_d < 4 :
                con_d += 1
            elif data[0] != 0x5678 :
                sign += 1
                if sign%2 == 1 :
                    if data[0]!=counter :
                        con_er += 1
                        print "error",hex(data[0])," ",hex(counter),i
                    counter = counter + 4
                else :
                    if data[0]!=0x0000 :
                        con_er += 1
                        print "error",hex(data[0])," ","0x0000"
    print j," (100MB)"
print con_er
fname.close()
