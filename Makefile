TOP = agent_npu_top

RTL = \
	rtl/agent_npu_regs.sv \
	rtl/agent_npu_top.sv


TB = tb/tb_smoke.cpp

OBJ_DIR = obj_dir

.PHONY: sim test clean

sim:
	verilator -Wall -Wno-fatal --cc $(RTL) --exe $(TB) --top-module $(TOP)
	$(MAKE) -C $(OBJ_DIR) -f V$(TOP).mk
	./$(OBJ_DIR)/V$(TOP)


test: sim

clean:
	rm -rf $(OBJ_DIR) *.vcd *.fst
