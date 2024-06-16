library common_lib;
context common_lib.common_context;
use osvvm.ScoreBoardPkg_slv.all;
use work.avmm_pkg.all;
use work.i2c_pkg.all;

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
    variable flags: std_logic_vector(1 downto 0) := (others => '0');
  begin
    SB <= NewID("I2C_write");
    wait until rst_o = '0';
    Log("*** Start of Testbench ***");
    Log("*** Start of Tests (AVMM) ***");
    
    -- master reads 1 byte
    dev_addr := "0101010";
    reg_addr := x"55";
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io,'1',3,reg_addr,dev_addr,1,datareg);
    WaitForBarrier(test_done);
    waitForFlags(avmm_trans_io,x"00",x"80000000",'0', CLK_DIVIDE_G * 2);

    readDataRegs(avmm_trans_io,datareg);
    Check(SB,DataRegArr_to_slv(datareg));
    AffirmIfEqual(Pop(SB),dev_addr,"I2C_write wrong dev address");
    AffirmIfEqual(Pop(SB),reg_addr,"I2C_write wrong reg address");

    -- master reads 64 byte
    dev_addr := "1111111";
    reg_addr := x"FF";
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io,'1',3,reg_addr,dev_addr,64,datareg);
    WaitForBarrier(test_done);
    waitForFlags(avmm_trans_io,x"00",x"80000000",'0', CLK_DIVIDE_G * 2);

    readDataRegs(avmm_trans_io,datareg);
    Check(SB,DataRegArr_to_slv(datareg));
    AffirmIfEqual(Pop(SB),dev_addr,"I2C_write wrong dev address");
    AffirmIfEqual(Pop(SB),reg_addr,"I2C_write wrong reg address");

    -- slave send no dev addr Ack
    dev_addr := "0000000";
    reg_addr := x"AA";
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io,'1',3,reg_addr,dev_addr,1,datareg);
    WaitForBarrier(test_done);
    waitForFlags(avmm_trans_io,x"00",x"80000000",'0', CLK_DIVIDE_G * 2);

    AffirmIfEqual(Pop(SB),dev_addr,"I2C_write wrong dev address");
    AvmmRead(avmm_trans_io,x"01","0001",flags);
    AffirmIfEqual(flags(1),'1',"Error flage not set");
    AvmmWrite(avmm_trans_io,x"01",x"F","1111");

    -- slave send no reg addr Ack
    dev_addr := "1010101";
    reg_addr := x"00";
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io,'1',3,reg_addr,dev_addr,1,datareg);
    WaitForBarrier(test_done);
    waitForFlags(avmm_trans_io,x"00",x"80000000",'0', CLK_DIVIDE_G * 2);

    AffirmIfEqual(Pop(SB),dev_addr,"I2C_write wrong dev address");
    AffirmIfEqual(Pop(SB),reg_addr,"I2C_write wrong reg address");
    AvmmRead(avmm_trans_io,x"01","0001",flags);
    AffirmIfEqual(flags(1),'1',"Error flage not set");
    AvmmWrite(avmm_trans_io,x"01",x"F","1111");

    -- slave send no 2nd dev addr Ack
    dev_addr := "1010101";
    reg_addr := x"00";
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io,'1',3,reg_addr,dev_addr,1,datareg);
    WaitForBarrier(test_done);
    waitForFlags(avmm_trans_io,x"00",x"80000000",'0', CLK_DIVIDE_G * 2);

    AffirmIfEqual(Pop(SB),dev_addr,"I2C_write wrong dev address");
    AffirmIfEqual(Pop(SB),reg_addr,"I2C_write wrong reg address");
    AvmmRead(avmm_trans_io,x"01","0001",flags);
    AffirmIfEqual(flags(1),'1',"Error flage not set");
    AvmmWrite(avmm_trans_io,x"01",x"F","1111");

    --master reads not enough bytes
    dev_addr := "1111111";
    reg_addr := x"FF";
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io,'1',3,reg_addr,dev_addr,3,datareg);
    WaitForBarrier(test_done);
    waitForFlags(avmm_trans_io,x"00",x"80000000",'0', CLK_DIVIDE_G * 2);

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

    
    Log("*** Start of Tests (I2C) ***");
    -- slave writes 1 byte
    data := (others => '0');
    data(7 downto 0) := x"AA";
    WaitForBarrier(test_start);
    Push(SB,data);
    I2CWrite(i2c_trans_io(3), data,1);
    (dev_addr,reg_addr,data) := std_logic_vector(i2c_trans_io(3).DataFromModel);
    Push(SB,dev_addr);
    Push(SB,reg_addr);
    WaitForBarrier(test_done);

    -- slave writes 64 byte
    for i in 0 to 63 loop
      data((i+1)*8-1 downto i*8) := std_logic_vector(to_unsigned(i,8));
    end loop;
    WaitForBarrier(test_start);
    Push(SB,data);
    I2CWrite(i2c_trans_io(3), data,64);
    (dev_addr,reg_addr,data) := std_logic_vector(i2c_trans_io(3).DataFromModel);
    Push(SB,dev_addr);
    Push(SB,reg_addr);
    WaitForBarrier(test_done);
    
    -- slave send no dev addr Ack
    WaitForBarrier(test_start);
    I2CWrite(i2c_trans_io(3), data,1,'1','0','0');
    (dev_addr,reg_addr,data) := std_logic_vector(i2c_trans_io(3).DataFromModel);
    Push(SB,dev_addr);
    WaitForBarrier(test_done);

    -- slave send no reg addr Ack
    WaitForBarrier(test_start);
    I2CWrite(i2c_trans_io(3), data,1,'0','1','0');
    (dev_addr,reg_addr,data) := std_logic_vector(i2c_trans_io(3).DataFromModel);
    Push(SB,dev_addr);
    Push(SB,reg_addr);
    WaitForBarrier(test_done);

    -- slave send no 2nd dev addr Ack
    WaitForBarrier(test_start);
    I2CWrite(i2c_trans_io(3), data,1,'0','0','1');
    (dev_addr,reg_addr,data) := std_logic_vector(i2c_trans_io(3).DataFromModel);
    Push(SB,dev_addr);
    Push(SB,reg_addr);
    WaitForBarrier(test_done);

    --master reads not enough bytes
    data := (others => '0');
    data(31 downto 0) := x"FF_00_55_AA";
    WaitForBarrier(test_start);
    Push(SB,data);
    I2CWrite(i2c_trans_io(3), data,4);
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
