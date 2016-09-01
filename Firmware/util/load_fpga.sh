#!/bin/sh
# author: Dong Wang
# The ssh tunnel should be fix first and the folder on server is fixed

# copy files from server
scp dwang@fpgalin.dhcp.lbl.gov:/home/dwang/mft_v789/SubModules/production/PXL_RDO_ise/PXL_RDO_top.bit .

#load firmware
source /opt/Xilinx/14.7/ISE_DS/settings64.sh
impact -batch ./impact_dong.cmd
