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
#analyze tb_dut.vhd

analyze tb_reset.vhd
analyze tb_avmm.vhd
analyze tb_i2c_interfaces_read.vhd
analyze tb_i2c_interfaces_write.vhd
analyze tb_i2c_read.vhd
analyze tb_i2c_write.vhd
analyze tb_i2c_interrupt.vhd

#RunTest tb_reset.vhd
#RunTest tb_avmm.vhd

TestCase tb_i2c_interfaces_slow_read
#simulate tb_i2c_interfaces_slow_read -gCLK_DIVIDE_G=2500
simulate tb_i2c_interfaces_slow_read -gCLK_DIVIDE_G=127

#TestCase tb_i2c_interfaces_fast_read
#simulate tb_i2c_interfaces_fast_read -gCLK_DIVIDE_G=2500
#simulate tb_i2c_interfaces_fast_read -gCLK_DIVIDE_G=63

#TestCase tb_i2c_interfaces_slow_write
#simulate tb_i2c_interfaces_slow_write -gCLK_DIVIDE_G=2500
#simulate tb_i2c_interfaces_slow_write -gCLK_DIVIDE_G=63

#TestCase tb_i2c_interfaces_fast_write
#simulate tb_i2c_interfaces_fast_write -gCLK_DIVIDE_G=2500
#simulate tb_i2c_interfaces_fast_write -gCLK_DIVIDE_G=63

#RunTest tb_i2c_write.vhd
#RunTest tb_i2c_read.vhd
#RunTest tb_i2c_interrupt.vhd

#simulate tb_dut