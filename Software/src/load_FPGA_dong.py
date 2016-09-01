#!/usr/bin/env python
__author__ = "Giacomo Contin"
__reviser__= "Dong Wang"
__version__ = "1.1"
__email__ = "gcontin@lbl.gov" "dongwang.ccnu@qq.com"
__status__ = "Prototype"

#!/usr/bin/env python
import sys
import os
import shutil
from subprocess import call


def load_FPGA():
	cmdstr1="source /opt/Xilinx/14.7/ISE_DS/settings64.sh" 
	cmdstr2="impact -batch ./impact_dong.cmd"
	cmdstr_all = cmdstr1+"; "+cmdstr2
	print str(cmdstr_all)
	call(cmdstr_all,shell=True)

	return()

load_FPGA()
