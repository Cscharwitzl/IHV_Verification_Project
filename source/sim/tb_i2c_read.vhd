library common_lib;
context common_lib.common_context;
use work.avmm_pkg.all;
use work.i2c_pkg.all;
use osvvm.ScoreBoardPkg_slv.all;

architecture tb_i2c_read_arc of dut_test_ctrl is

  signal test_start : integer_barrier;
  signal test_done  : integer_barrier;

  function SetupControlReg(
      go       : boolean;
      len      : integer;
      reg_addr : std_logic_vector(7 downto 0);
      addr     : std_logic_vector(6 downto 0);
      read     : boolean;
      intr_en  : boolean;
      rst      : boolean)
    return std_logic_vector is
    variable reg : std_logic_vector(31 downto 0) := (others => '0');
  begin
    reg(31) := '1' when go else '0';
    reg(29 downto 24) := std_logic_vector(to_unsigned(len, 6));
    reg(23 downto 16) := reg_addr;
    reg(11 downto 5) := addr;
    reg(4) := '1' when read else '0';
    reg(1) := '1' when intr_en else '0';
    reg(0) := '1' when rst else '0';
    return reg;
  end function;

  signal SB : ScoreBoardIDType;

begin

  CreateClock(clk_o, 10 ns);
  CreateReset(rst_o, '1', clk_o, 100 ns, 0 ns);

  stimuli_p: process is
    variable addr     : std_logic_vector(6 downto 0);
    variable byte_en  : std_logic_vector(3 downto 0);
    variable datareg  : DataRegArrayT(15 downto 0) := (others => (others => '0'));
    variable dev_addr : std_logic_vector(6 downto 0);
    variable reg_addr : std_logic_vector(7 downto 0);
  begin
    SB <= NewID("I2C_Read");
    wait until rst_o = '0';
    Log("*** Start of Testbench ***");
    WaitForBarrier(test_start);

    Log("*** Start of Tests (AVMM) ***");

    -- read 1 byte
    datareg(0) := x"00_00_00_55";
    dev_addr := "1010101";
    reg_addr := x"AA";
    Push(SB, DataRegArr_to_slv(datareg));
    Push(SB, dev_addr);
    Push(SB, reg_addr);
    startI2CTransfereInAVMM(avmm_trans_io, '0', 3, reg_addr, dev_addr, 1, datareg);
    WaitForBarrier(test_done);

    -- read 4 byte
    datareg(0) := x"22_FF_AA_55";
    dev_addr := "0101010";
    reg_addr := x"55";
    Push(SB, DataRegArr_to_slv(datareg));
    Push(SB, dev_addr);
    Push(SB, reg_addr);
    startI2CTransfereInAVMM(avmm_trans_io, '0', 3, reg_addr, dev_addr, 4, datareg);
    WaitForBarrier(test_done);

    --read wrong length slave
    datareg(0) := x"22_FF_AA_55";
    dev_addr := "1010101";
    reg_addr := x"AA";
    Push(SB, DataRegArr_to_slv(datareg));
    Push(SB, dev_addr);
    Push(SB, reg_addr);
    startI2CTransfereInAVMM(avmm_trans_io, '0', 3, reg_addr, dev_addr, 5, datareg);
    WaitForBarrier(test_done);

    --read wrong length master
    datareg(0) := x"22_FF_AA_55";
    dev_addr := "0101010";
    reg_addr := x"55";
    Push(SB, DataRegArr_to_slv(datareg));
    Push(SB, dev_addr);
    Push(SB, reg_addr);
    startI2CTransfereInAVMM(avmm_trans_io, '0', 3, reg_addr, dev_addr, 4, datareg);
    WaitForBarrier(test_done);

    Log("*** End of Tests (AVMM) ***");
    Log("*** End of Testbench ***");

    std.env.stop;
  end process;

  read_p: process is
    variable data_read : std_logic_vector(64 * 8 - 1 downto 0) := (others => '0');
    variable addr      : std_logic_vector(14 downto 0)         := (others => '0');
  begin
    WaitForBarrier(test_start);

    Log("*** Start of Tests (I2C) ***");

    -- read 1 byte
    I2CRead(i2c_trans_io(3), x"55", data_read, 1);
    addr := std_logic_vector(i2c_trans_io(3).Address);
    Check(SB, data_read);
    Check(SB, addr(14 downto 8));
    Check(SB, addr(7 downto 0));
    WaitForBarrier(test_done);
    test_done <= 1;

    --read 4 byte
    I2CRead(i2c_trans_io(3), x"00", data_read, 4);
    addr := std_logic_vector(i2c_trans_io(3).Address);
    Check(SB, data_read);
    Check(SB, addr(14 downto 8));
    Check(SB, addr(7 downto 0));
    WaitForBarrier(test_done);
    test_done <= 1;

    --read wrong length slave
    I2CRead(i2c_trans_io(3), x"00", data_read, 4);
    addr := std_logic_vector(i2c_trans_io(3).Address);
    Check(SB, data_read);
    Check(SB, addr(14 downto 8));
    Check(SB, addr(7 downto 0));
    WaitForBarrier(test_done);
    test_done <= 1;

    --read wrong length master
    I2CRead(i2c_trans_io(3), x"00", data_read, 5);
    addr := std_logic_vector(i2c_trans_io(3).Address);
    Check(SB, data_read);
    Check(SB, addr(14 downto 8));
    Check(SB, addr(7 downto 0));
    WaitForBarrier(test_done);
    test_done <= 1;

    Log("*** End of Tests (I2C) ***");

    wait;
  end process;

end architecture;

configuration tb_i2c_read of dut_harness is
  for harness_arc
    for dut_test_ctrl_inst: dut_test_ctrl
      use entity work.dut_test_ctrl(tb_i2c_read_arc);
    end for;
  end for;
end configuration;
