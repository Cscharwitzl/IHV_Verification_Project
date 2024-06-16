library common_lib;
context common_lib.common_context;
use osvvm.ScoreBoardPkg_slv.all;
use work.avmm_pkg.all;
use work.i2c_pkg.all;

architecture tb_i2c_interfaces_arc of dut_test_ctrl is
  constant id : string := "I2C Interfaces";

  signal SB : ScoreBoardIDType;
  signal tb_start, tb_end, test_start, test_end : integer_barrier;
begin

  CreateClock(clk_o, 10 ns);
  CreateReset(rst_o, '1', clk_o, 100 ns, 0 ns);
  
  stimuli_p: process is
  begin
    SB <= NewID(id);
    Log("*** Start of Testbench ***");
    wait for rst_o = '0';
    WaitForBarrier(tb_start);
    -- Tests here -- 
    WaitForBarrier(test_start);
    WaitForBarrier(test_end);

    WaitForBarrier(tb_end);
    Log("*** End of Testbench ***");
    std.env.stop;
  end process;

  i2c_p: process is
  begin
    WaitForBarrier(tb_start);
    -- Tests here --
    WaitForBarrier(test_start);
    WaitForBarrier(test_end);

    WaitForBarrier(tb_end);
  end process;
  
end architecture;

configuration tb_i2c_interfaces of dut_harness is
  for harness_arc
    for dut_test_ctrl_inst: dut_test_ctrl
      use entity work.dut_test_ctrl(tb_i2c_interfaces_arc) ; 
    end for; 
  end for; 
end configuration;