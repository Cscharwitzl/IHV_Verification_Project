library common_lib;
context common_lib.common_context;
use osvvm.ScoreBoardPkg_slv.all;
use work.avmm_pkg.all;
use work.i2c_pkg.all;

architecture tb_i2c_read_arc of dut_test_ctrl is

  signal tb_start   : integer_barrier;
  signal test_start : integer_barrier;
  signal test_done  : integer_barrier;

  signal SB : ScoreBoardIDType;

begin

  CreateClock(clk_o, 10 ns);
  CreateReset(rst_o, '1', clk_o, 100 ns, 0 ns);

  stimuli_p: process is
    variable addr     : std_logic_vector(6 downto 0);
    variable byte_en  : std_logic_vector(3 downto 0);
    variable datareg  : DataRegArrayT(15 downto 0)   := (others => (others => '0'));
    variable dev_addr : std_logic_vector(6 downto 0);
    variable reg_addr : std_logic_vector(7 downto 0);
    variable flags    : std_logic_vector(1 downto 0) := (others => '0');

    variable tmp : std_logic_vector(3 downto 0);
  begin
    SB <= NewID("I2C_Read");
    wait until rst_o = '0';
    Log("*** Start of Testbench ***");

    WaitForBarrier(tb_start);

    Log("*** Start of Tests (AVMM) ***");

    -- master writes 1 byte
    datareg := (others => (others => '0'));
    datareg(0) := x"00_00_00_55";
    dev_addr := "1010101";
    reg_addr := x"AA";
    Push(SB, DataRegArr_to_slv(datareg));
    Push(SB, dev_addr);
    Push(SB, reg_addr);
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, '0', "1000", reg_addr, dev_addr, 1, datareg);
    WaitForBarrier(test_done);
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);

    -- master writes 64 bytes
    datareg := (others => (others => '0'));
    for i in datareg'range loop
      tmp := std_logic_vector(to_unsigned(i, 4));
      datareg(i) := tmp & tmp & tmp & tmp & tmp & tmp & tmp & tmp;
    end loop;
    dev_addr := "0101010";
    reg_addr := x"55";
    Push(SB, DataRegArr_to_slv(datareg));
    Push(SB, dev_addr);
    Push(SB, reg_addr);
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, '0', "1000", reg_addr, dev_addr, 64, datareg);
    WaitForBarrier(test_done);
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);

    -- slave sends no ack for dev addr
    datareg := (others => (others => '0'));
    datareg(0) := x"00_00_00_55";
    dev_addr := "1111111";
    reg_addr := x"00";
    Push(SB, dev_addr);
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, '0', "1000", reg_addr, dev_addr, 1, datareg);
    WaitForBarrier(test_done);
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);

    AvmmRead(avmm_trans_io, x"01", "0001", flags);
    AffirmIfEqual(flags(1), '1', "Error flage not set");
    AvmmWrite(avmm_trans_io, x"01", x"F", "1111");

    -- slave sends no ack for reg addr
    datareg := (others => (others => '0'));
    datareg(0) := x"00_00_00_AA";
    dev_addr := "0000000";
    reg_addr := x"FF";
    Push(SB, dev_addr);
    Push(SB, reg_addr);
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, '0', "1000", reg_addr, dev_addr, 1, datareg);
    WaitForBarrier(test_done);
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);

    AvmmRead(avmm_trans_io, x"01", "0001", flags);
    AffirmIfEqual(flags(1), '1', "Error flage not set");
    AvmmWrite(avmm_trans_io, x"01", x"F", "1111");

    -- slave sends no ack for 1 byte
    datareg := (others => (others => '0'));
    datareg(0) := x"00_00_00_AA";
    dev_addr := "0000000";
    reg_addr := x"FF";
    Push(SB, DataRegArr_to_slv(datareg));
    Push(SB, dev_addr);
    Push(SB, reg_addr);
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, '0', "1000", reg_addr, dev_addr, 1, datareg);
    WaitForBarrier(test_done);
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);

    AvmmRead(avmm_trans_io, x"01", "0001", flags);
    AffirmIfEqual(flags(1), '1', "Error flage not set");
    AvmmWrite(avmm_trans_io, x"01", x"F", "1111");

    -- slave sends no ack for 5 th byte
    datareg := (others => (others => '0'));
    datareg(0) := x"00_FF_55_AA";
    datareg(1) := x"00_00_00_22";
    dev_addr := "0000000";
    reg_addr := x"FF";
    Push(SB, DataRegArr_to_slv(datareg));
    Push(SB, dev_addr);
    Push(SB, reg_addr);
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, '0', "1000", reg_addr, dev_addr, 8, datareg);
    WaitForBarrier(test_done);
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);

    AvmmRead(avmm_trans_io, x"01", "0001", flags);
    AffirmIfEqual(flags(1), '1', "Error flage not set");
    AvmmWrite(avmm_trans_io, x"01", x"F", "1111");   

    -- master writes too much data
    datareg(0) := x"22_FF_AA_55";
    dev_addr := "1010101";
    reg_addr := x"AA";
    Push(SB, DataRegArr_to_slv(datareg));
    Push(SB, dev_addr);
    Push(SB, reg_addr);
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, '0', "1000", reg_addr, dev_addr, 5, datareg);
    WaitForBarrier(test_done);
    AvmmWrite(avmm_trans_io,x"00",x"00000001","0001");
    waitForFlags(avmm_trans_io,x"00",x"00000001",'0', CLK_DIVIDE_G * 2);

    -- master writes not enough data
    datareg(0) := x"22_FF_AA_55";
    dev_addr := "0101010";
    reg_addr := x"55";
    Push(SB, DataRegArr_to_slv(datareg));
    Push(SB, dev_addr);
    Push(SB, reg_addr);
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, '0', "1000", reg_addr, dev_addr, 4, datareg);
    WaitForBarrier(test_done);

    Log("*** End of Tests (AVMM) ***");
    Log("*** End of Testbench ***");

    std.env.stop;
  end process;

  read_p: process is
    variable data_read : std_logic_vector(7 + 8 + 64 * 8 - 1 downto 0) := (others => '0');
    variable dev_addr  : std_logic_vector(6 downto 0);
    variable reg_addr  : std_logic_vector(7 downto 0);
    variable data      : std_logic_vector(64 * 8 - 1 downto 0);
  begin
    WaitForBarrier(tb_start);
    Log("*** Start of Tests (I2C) ***");

    -- slave read 1 byte
    WaitForBarrier(test_start);
    I2CRead(i2c_trans_io(3), data_read, 1);
    (dev_addr, reg_addr, data) := data_read;
    Check(SB, data);
    Check(SB, dev_addr);
    Check(SB, reg_addr);
    WaitForBarrier(test_done);

    -- slave read 64 byte
    WaitForBarrier(test_start);
    I2CRead(i2c_trans_io(3), data_read, 64);
    (dev_addr, reg_addr, data) := data_read;
    Check(SB, data);
    Check(SB, dev_addr);
    Check(SB, reg_addr);
    WaitForBarrier(test_done);

    -- slave sends no ack for dev addr
    WaitForBarrier(test_start);
    I2CRead(i2c_trans_io(3), data_read, 1, '1', '0',(others => '0'));
    (dev_addr, reg_addr, data) := data_read;
    Check(SB, dev_addr);
    WaitForBarrier(test_done);

    -- slave sends no ack for reg addr
    WaitForBarrier(test_start);
    I2CRead(i2c_trans_io(3), data_read, 1, '0', '1',(others => '0'));
    (dev_addr, reg_addr, data) := data_read;
    Check(SB, dev_addr);
    Check(SB, reg_addr);
    WaitForBarrier(test_done);

    -- slave sends no ack for 1 byte
    WaitForBarrier(test_start);
    I2CRead(i2c_trans_io(3), data_read, 1, '0', '0',(0 => '1', others => '0'));
    (dev_addr, reg_addr, data) := data_read;
    Check(SB, data);
    Check(SB, dev_addr);
    Check(SB, reg_addr);
    WaitForBarrier(test_done);

    -- slave sends no ack for 5 th byte
    WaitForBarrier(test_start);
    I2CRead(i2c_trans_io(3), data_read, 10, '0', '0',(5 => '1', others => '0'));
    (dev_addr, reg_addr, data) := data_read;
    Check(SB, data);
    Check(SB, dev_addr);
    Check(SB, reg_addr);
    WaitForBarrier(test_done);

    -- master writes too much data
    WaitForBarrier(test_start);
    I2CRead(i2c_trans_io(3), data_read, 4);
    (dev_addr,reg_addr,data) := data_read;
    Check(SB, data);
    Check(SB, dev_addr);
    Check(SB, reg_addr);
    WaitForBarrier(test_done);

    -- master writes not enough data
    WaitForBarrier(test_start);
    I2CRead(i2c_trans_io(3), data_read, 5);
    (dev_addr,reg_addr,data) := data_read;
    Check(SB, data);
    Check(SB, dev_addr);
    Check(SB, reg_addr);
    WaitForBarrier(test_done);

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
