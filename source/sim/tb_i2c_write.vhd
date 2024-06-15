library common_lib;
context common_lib.common_context;
use work.avmm_pkg.all;
use work.i2c_pkg.all;
use osvvm.ScoreBoardPkg_slv.all;

architecture tb_i2c_write_arc of dut_test_ctrl is
  
  signal test_start : integer_barrier;
  signal test_done  : integer_barrier;

  signal SB : ScoreBoardIDType;

begin

  CreateClock(clk_o, 10 ns);
  CreateReset(rst_o, '1', clk_o, 100 ns, 0 ns);

  stimuli_p: process is
    variable reg_addr      : std_logic_vector(7 downto 0);
    variable dev_addr: std_logic_vector(6 downto 0);
    variable datareg : DataRegArrayT(15 downto 0) := (others => (others => '0'));
  begin
    SB <= NewID("I2C_write");
    wait until rst_o = '0';
    Log("*** Start of Testbench ***");
    WaitForBarrier(test_start);

    Log("*** Start of Tests (AVMM) ***");

    -- master reads 1 byte
    dev_addr := "0101010";
    reg_addr := x"55";
    startI2CTransfereInAVMM(avmm_trans_io,'1',3,reg_addr,dev_addr,1,datareg);
    WaitForBarrier(test_done);
    readDataRegs(avmm_trans_io,datareg);
    Check(SB,DataRegArr_to_slv(datareg));
    AffirmIfEqual(Pop(SB),dev_addr,"I2C_write wrong dev address");
    AffirmIfEqual(Pop(SB),reg_addr,"I2C_write wrong reg address");

    -- master reads 8 byte
    dev_addr := "1111111";
    reg_addr := x"FF";
    startI2CTransfereInAVMM(avmm_trans_io,'1',3,reg_addr,dev_addr,8,datareg);
    WaitForBarrier(test_done);
    readDataRegs(avmm_trans_io,datareg);
    Check(SB,DataRegArr_to_slv(datareg));
    AffirmIfEqual(Pop(SB),dev_addr,"I2C_write wrong dev address");
    AffirmIfEqual(Pop(SB),reg_addr,"I2C_write wrong reg address");

    
    Log("*** End of Tests (AVMM) ***");
    Log("*** End of Testbench ***");

    std.env.stop;
  end process;

  read_p: process is
    variable data : std_logic_vector(64*8-1 downto 0) := (others => '0');
    variable reg_addr      : std_logic_vector(7 downto 0);
    variable dev_addr: std_logic_vector(6 downto 0);
  begin
    WaitForBarrier(test_start);

    Log("*** Start of Tests (I2C) ***");

    -- slave writes 1 byte
    data := (others => '0');
    data(7 downto 0) := x"AA";
    Push(SB,data);
    I2CWrite(i2c_trans_io(3), data,1);
    (dev_addr,reg_addr,data) := std_logic_vector(i2c_trans_io(3).DataFromModel);
    Push(SB,dev_addr);
    Push(SB,reg_addr);
    WaitForBarrier(test_done);

    -- slave writes 8 byte
    data := (others => '0');
    data(63 downto 0) := x"89_9a_0c_28_9a_54_44_f5";
    Push(SB,data);
    I2CWrite(i2c_trans_io(3), data,8);
    (dev_addr,reg_addr,data) := std_logic_vector(i2c_trans_io(3).DataFromModel);
    Push(SB,dev_addr);
    Push(SB,reg_addr);
    WaitForBarrier(test_done);

    Log("*** End of Tests (I2C) ***");

    
    wait;
  end process;

end architecture;

configuration tb_i2c_write of dut_harness is
  for harness_arc
    for dut_test_ctrl_inst: dut_test_ctrl
      use entity work.dut_test_ctrl(tb_i2c_write_arc);
    end for;
  end for;
end configuration;
