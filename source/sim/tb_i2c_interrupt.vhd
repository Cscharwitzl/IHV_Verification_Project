library common_lib;
context common_lib.common_context;
use osvvm.ScoreBoardPkg_slv.all;
use work.avmm_pkg.all;
use work.i2c_pkg.all;

architecture tb_i2c_interrupt_arc of dut_test_ctrl is
  constant id : string := "I2C Interrupt";

  signal SB : ScoreBoardIDType;
  signal tb_start, tb_end, test_start, test_end : integer_barrier;

  variable datareg  : DataRegArrayT(15 downto 0)   := (others => (others => '0'));
begin

  CreateClock(clk_o, 10 ns);
  CreateReset(rst_o, '1', clk_o, 100 ns, 0 ns);
  
  stimuli_p: process is
  begin
    SB <= NewID(id);
    Log("*** Start of Testbench ***");
    wait for rst_o = '0';
    WaitForBarrier(tb_start);

    --interrupt at transfer without error
    datareg(7 downto 0) := x"55";
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io,'0',0,x"AA","1111111",1,datareg);
    WaitForBarrier(test_end);
    waitForFlags(avmm_trans_io,x"00",x"80000000",'0',CLK_DIVIDE_G);
    AffirmIfEqual(irq_i, '1', "Interrupt output is not set");
    AvmmRead(avmm_trans_io,x"01","0001",datareg(15));
    AffirmIfEqual(datareg(15)(0),'1',"Interrupt status is not set");


    --interrupt at transfer with error

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

configuration tb_i2c_interrupt of dut_harness is
  for harness_arc
    for dut_test_ctrl_inst: dut_test_ctrl
      use entity work.dut_test_ctrl(tb_i2c_interrupt_arc) ; 
    end for; 
  end for; 
end configuration;