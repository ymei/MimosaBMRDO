# author : Dong Wang
# the ssh tunnel should be fix first and the folder on server is fixed

#copy files from server
scp dwang@fpgalin.dhcp.lbl.gov:/home/dwang/mft_v789/SubModules/production/PXL_RDO_ise/PXL_RDO_top.bit ./
#load firmware
./load_FPGA_dong.py
