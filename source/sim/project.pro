library verification_project_lib

analyze ../vu/avmm_pkg.vhd
analyze ../vu/avmm_vu.vhd
analyze ../vu/i2c_pkg.vhd
analyze ../vu/i2c_vu.vhd

analyze ../dut/math_pkg.vhd
analyze ../dut/clock_crosser.vhd
analyze ../dut/i2c_multi_bus_controller_memory.vhd
analyze ../dut/i2c_multi_bus_controller.vhd

analyze dut_test_ctrl.vhd 
analyze dut_harness.vhd
analyze tb_dut.vhd

#RunTest tb_avmm.vhd
#RunTest tb_reset.vhd

analyze tb_i2c_interfaces.vhd
#RunTest tb_i2c_interfaces.vhd
simulate tb_i2c_interfaces_fast
simulate tb_i2c_interfaces_slow


#RunTest tb_i2c_communication_header.vhd
#RunTest tb_i2c_write.vhd
#RunTest tb_i2c_read.vhd
#RunTest tb_i2c_interrupt.vhd

#simulate tb_dut