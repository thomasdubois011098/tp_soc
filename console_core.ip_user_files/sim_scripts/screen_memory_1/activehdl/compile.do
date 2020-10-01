vlib work
vlib activehdl

vlib activehdl/blk_mem_gen_v8_3_5
vlib activehdl/xil_defaultlib

vmap blk_mem_gen_v8_3_5 activehdl/blk_mem_gen_v8_3_5
vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work blk_mem_gen_v8_3_5  -v2k5 \
"../../../ipstatic/simulation/blk_mem_gen_v8_3.v" \

vlog -work xil_defaultlib  -v2k5 \
"../../../../console_core.srcs/sources_1/ip/screen_memory_1/sim/screen_memory.v" \


vlog -work xil_defaultlib "glbl.v"

