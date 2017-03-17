from multiprocessing import Process, Manager, Lock
from multiprocessing import Value, Array
from multiprocessing import Queue
import numpy
from matplotlib import pyplot
import matplotlib as mpl
import matplotlib.animation as animation
from matplotlib.colors import LogNorm
import numpy as np
class Disper():
    def run(self, q_pro_dis, lock, stop):
        mapsbyte = np.ctypeslib.as_array(q_pro_dis.get_obj())
        mapsdis = mapsbyte.reshape(928,960)
        maps = numpy.zeros(shape=(928,960))
        fig = pyplot.figure()
        img = pyplot.imshow(maps, cmap='viridis',norm=LogNorm(vmin=1, vmax=100))
        pyplot.colorbar(img, orientation='vertical')
        while stop.value==1 :
            # -- display processing
            def update(*args) :
                global q_pro_dis
                with lock :
                    img.set_data(mapsdis)
                return img
            anim = animation.FuncAnimation(fig, update, interval=50)
            pyplot.show()
        print "display terminate"
