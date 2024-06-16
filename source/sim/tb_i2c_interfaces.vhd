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
    variable datareg : DataRegArrayT(0 to 15);
  begin
    SB <= NewID(id);
    wait until rst_o = '0';
    WaitForBarrier(tb_start);
    Log("*** Start of Testbench ***");

    AffirmIfEqual(NUM_BUSSES_G, 4, "Wrong amount of I2C busses.");

    datareg(0) := x"33_22_11_A5";
    datareg(1) := x"77_66_55_44";
    datareg(2) := x"BB_AA_99_88";
    datareg(3) := x"FF_EE_DD_CC";

    Push(SB, datareg(0)(7 downto 0));
    Push(SB, datareg(0)(7 downto 0));
    WaitForBarrier(test_start);
    Log("*** Here 1a ***");
    startI2CTransfereInAVMM(avmm_trans_io, '1', 0, x"00", "0000000", 1, datareg);
    WaitForBarrier(test_end);
    Log("*** Here 2a ***");
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);
    WaitForBarrier(test_start);
    Log("*** Here 3a ***");
    startI2CTransfereInAVMM(avmm_trans_io, '1', 0, x"01", "0000001", 1, datareg);
    WaitForBarrier(test_end);
    Log("*** Here 4a ***");
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);

    WaitForBarrier(tb_end);
    Log("*** End of Testbench ***");
    std.env.stop;
  end process;

  i2c_p: process is
    variable read_data : std_logic_vector(64*8-1 downto 0); 
  begin
    WaitForBarrier(tb_start);

    WaitForBarrier(test_start);
    Log("*** Here 1b ***");
    I2CRead(i2c_trans_io(0), read_data, 1);
    WaitForBarrier(test_end);
    Log("*** Here 2b ***");
    Check(SB, read_data(7 downto 0));
    WaitForBarrier(test_start);
    Log("*** Here 3b ***");
    I2CRead(i2c_trans_io(0), read_data, 1);
    WaitForBarrier(test_end);
    Log("*** Here 4b ***");
    Check(SB, read_data(7 downto 0));

    WaitForBarrier(tb_end);
    wait;
  end process;
  
end architecture;

configuration tb_i2c_interfaces of dut_harness is
  for harness_arc
    for dut_test_ctrl_inst: dut_test_ctrl
      use entity work.dut_test_ctrl(tb_i2c_interfaces_arc) ; 
    end for; 
  end for; 
end configuration;