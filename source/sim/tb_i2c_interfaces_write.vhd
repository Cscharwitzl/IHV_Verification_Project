library common_lib;
context common_lib.common_context;
use osvvm.ScoreBoardPkg_slv.all;
use work.avmm_pkg.all;
use work.i2c_pkg.all;

architecture tb_i2c_interfaces_write_arc of dut_test_ctrl is
  constant id : string    := "I2C Interfaces Write";
  constant op : std_logic := '1'; -- Write

  signal SB                                     : ScoreBoardIDType;
  signal tb_start, tb_end, test_start, test_end : integer_barrier;
begin

  CreateClock(clk_o, CLK_PERIOD_G * 1 ns);
  CreateReset(rst_o, '1', clk_o, 100 ns, 0 ns);

  stimuli_p: process is
    variable bus_en    : std_logic_vector(3 downto 0) := "0001";
    variable addr      : std_logic_vector(6 downto 0);
    variable reg_addr  : std_logic_vector(7 downto 0);
    variable datareg   : DataRegArrayT(0 to 15)       := (others => (others => '0'));
    variable read_data : std_logic_vector(31 downto 0);
  begin
    SB <= NewID(id);
    wait until rst_o = '0';
    WaitForBarrier(tb_start);
    Log("*** Start of Testbench interfaces write***");
    Log("* CLK PERIOD: " & integer'image(CLK_PERIOD_G) & " ns *");
    AffirmIfEqual(NUM_BUSSES_G, 4, "Wrong amount of I2C busses.");

    datareg(0) := x"33_22_11_A5";
    datareg(1) := x"77_66_55_44";
    datareg(2) := x"BB_AA_99_88";
    datareg(3) := x"FF_EE_DD_CC";

    -- Bus 0
    addr := "0000000";
    reg_addr := x"00";
    Push(SB, addr);
    Push(SB, reg_addr);
    Push(SB, datareg(0)(7 downto 0));
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, op, bus_en, reg_addr, addr, 1, datareg);
    WaitForBarrier(test_end);
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);
    addr := "0000001";
    reg_addr := x"01";
    Push(SB, addr);
    Push(SB, reg_addr);
    Push(SB, datareg(0)(7 downto 0));
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, op, bus_en, reg_addr, addr, 1, datareg);
    WaitForBarrier(test_end);
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);

    bus_en := "0010";
    -- Bus 1
    addr := "1010101";
    reg_addr := x"11";
    Push(SB, addr);
    Push(SB, reg_addr);
    Push(SB, datareg(0)(7 downto 0));
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, op, bus_en, reg_addr, addr, 1, datareg);
    WaitForBarrier(test_end);
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);
    addr := "0000001";
    reg_addr := x"55";
    Push(SB, addr);
    Push(SB, reg_addr);
    Push(SB, datareg(0)(7 downto 0));
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, op, bus_en, reg_addr, addr, 1, datareg);
    WaitForBarrier(test_end);
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);

    bus_en := "0100";
    -- Bus 2
    addr := "1010101";
    reg_addr := x"88";
    Push(SB, addr);
    Push(SB, reg_addr);
    Push(SB, datareg(0)(7 downto 0));
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, op, bus_en, reg_addr, addr, 1, datareg);
    WaitForBarrier(test_end);
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);
    addr := "0000001";
    reg_addr := x"AA";
    Push(SB, addr);
    Push(SB, reg_addr);
    Push(SB, datareg(0)(7 downto 0));
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, op, bus_en, reg_addr, addr, 1, datareg);
    WaitForBarrier(test_end);
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);

    bus_en := "1000";
    -- Bus 3
    addr := "1010101";
    reg_addr := x"2C";
    Push(SB, addr);
    Push(SB, reg_addr);
    Push(SB, datareg(0)(7 downto 0));
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, op, bus_en, reg_addr, addr, 1, datareg);
    WaitForBarrier(test_end);
    waitForFlags(avmm_trans_io, x"00", x"80000000", '0', CLK_DIVIDE_G * 2);
    addr := "0000001";
    reg_addr := x"FF";
    Push(SB, addr);
    Push(SB, reg_addr);
    Push(SB, datareg(0)(7 downto 0));
    WaitForBarrier(test_start);
    startI2CTransfereInAVMM(avmm_trans_io, op, bus_en, reg_addr, addr, 1, datareg);
    WaitForBarrier(test_end);

    WaitForBarrier(tb_end);
    Log("*** End of Testbench interfaces write ***");
    std.env.stop;
  end process;

  i2c_p: process is
    variable read_data : std_logic_vector(7 + 8 + 64 * 8 - 1 downto 0);
    variable addr      : std_logic_vector(6 downto 0);
    variable reg_addr  : std_logic_vector(7 downto 0);
    variable data      : std_logic_vector(64 * 8 - 1 downto 0);
  begin
    WaitForBarrier(tb_start);

    data := (15 downto 8 => x"11", 7 downto 0 => x"00", others => '0');

    -- Bus 0
    WaitForBarrier(test_start);
    I2CWrite(i2c_trans_io(0), data, 1);
    WaitForBarrier(test_end);
    read_data := SafeResize(i2c_trans_io(0).DataFromModel, read_data'length);
    (addr, reg_addr, data) := read_data;
    Check(SB, addr);
    Check(SB, reg_addr);
    Check(SB, data(7 downto 0));
    WaitForBarrier(test_start);
    I2CWrite(i2c_trans_io(0), data, 1);
    WaitForBarrier(test_end);
    read_data := SafeResize(i2c_trans_io(0).DataFromModel, read_data'length);
    (addr, reg_addr, data) := read_data;
    Check(SB, addr);
    Check(SB, reg_addr);
    Check(SB, data(7 downto 0));

    Log("* Bus0 finished *");

    -- Bus 1
    WaitForBarrier(test_start);
    I2CWrite(i2c_trans_io(1), data, 1);
    WaitForBarrier(test_end);
    read_data := SafeResize(i2c_trans_io(1).DataFromModel, read_data'length);
    (addr, reg_addr, data) := read_data;
    Check(SB, addr);
    Check(SB, reg_addr);
    Check(SB, data(7 downto 0));
    WaitForBarrier(test_start);
    I2CWrite(i2c_trans_io(1), data, 1);
    WaitForBarrier(test_end);
    read_data := SafeResize(i2c_trans_io(1).DataFromModel, read_data'length);
    (addr, reg_addr, data) := read_data;
    Check(SB, addr);
    Check(SB, reg_addr);
    Check(SB, data(7 downto 0));

    Log("* Bus1 finished *");

    -- Bus 2
    WaitForBarrier(test_start);
    I2CWrite(i2c_trans_io(2), data, 1);
    WaitForBarrier(test_end);
    read_data := SafeResize(i2c_trans_io(2).DataFromModel, read_data'length);
    (addr, reg_addr, data) := read_data;
    Check(SB, addr);
    Check(SB, reg_addr);
    Check(SB, data(7 downto 0));
    WaitForBarrier(test_start);
    I2CWrite(i2c_trans_io(2), data, 1);
    WaitForBarrier(test_end);
    read_data := SafeResize(i2c_trans_io(2).DataFromModel, read_data'length);
    (addr, reg_addr, data) := read_data;
    Check(SB, addr);
    Check(SB, reg_addr);
    Check(SB, data(7 downto 0));

    Log("* Bus2 finished *");

    -- Bus 3
    WaitForBarrier(test_start);
    I2CWrite(i2c_trans_io(3), data, 1);
    WaitForBarrier(test_end);
    read_data := SafeResize(i2c_trans_io(3).DataFromModel, read_data'length);
    (addr, reg_addr, data) := read_data;
    Check(SB, addr);
    Check(SB, reg_addr);
    Check(SB, data(7 downto 0));
    WaitForBarrier(test_start);
    I2CWrite(i2c_trans_io(3), data, 1);
    WaitForBarrier(test_end);
    read_data := SafeResize(i2c_trans_io(3).DataFromModel, read_data'length);
    (addr, reg_addr, data) := read_data;
    Check(SB, addr);
    Check(SB, reg_addr);
    Check(SB, data(7 downto 0));

    Log("* Bus3 finished *");

    WaitForBarrier(tb_end);
    wait;
  end process;

end architecture;

configuration tb_i2c_interfaces_fast_write of dut_harness is
  for harness_arc
    for dut_test_ctrl_inst: dut_test_ctrl
      use entity work.dut_test_ctrl(tb_i2c_interfaces_write_arc)
        generic map (
          CLK_PERIOD_G => 8
        );
    end for;
  end for;
end configuration;

configuration tb_i2c_interfaces_slow_write of dut_harness is
  for harness_arc
    for dut_test_ctrl_inst: dut_test_ctrl
      use entity work.dut_test_ctrl(tb_i2c_interfaces_write_arc)
        generic map (
          CLK_PERIOD_G => 40
        );
    end for;
  end for;
end configuration;
