from ctypes import *


class Cmd:
    # soname = "./build/lib.freebsd-11.0-STABLE-amd64-2.7/command.so"
    soname = "./build/lib.linux-x86_64-2.7/command.so"
    nmax = 1024

    def __init__(self):
        self.cmdGen = cdll.LoadLibrary(self.soname)
        self.buf = create_string_buffer(self.nmax)

    def write_register(self, addr, val):
        cfun = self.cmdGen.cmd_write_register
        buf = addressof(self.buf)
        n = cfun(byref(c_void_p(buf)), c_uint(addr), c_uint(val))
        return self.buf.raw[0:n]

if __name__ == "__main__":
    cmd = Cmd()
    ret = cmd.write_register(1, 0x5a5a)
    print [hex(ord(s)) for s in ret]
