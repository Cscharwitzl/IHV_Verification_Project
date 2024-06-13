library common_lib;
context common_lib.common_context;
use work.avmm_pkg.all;
use work.i2c_pkg.all;

architecture tb_i2c_arc of dut_test_ctrl is
  
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

begin

  CreateClock(clk_o, 10 ns);
  CreateReset(rst_o, '1', clk_o, 100 ns, 0 ns);

  stimuli_p: process is
    variable addr      : std_logic_vector(6 downto 0);
    variable byte_en   : std_logic_vector(3 downto 0);
    variable data : DataRegArrayT(15 downto 0) := (others => (others => '0'));
  begin

    wait until rst_o = '0';
    Log("*** Start of Testbench ***");
    WaitForBarrier(test_start);

    Log("*** Start of Tests (AVMM) ***");

    data(0) := x"22_FF_AA_55";
    startI2CTransfereInAVMM(avmm_trans_io,'0',3,x"AA","1010101",1,data);
    
    WaitForBarrier(test_done);

    startI2CTransfereInAVMM(avmm_trans_io,'0',3,x"55","0101010",2,data);
    Log("*** End of Tests (AVMM) ***");
    Log("*** End of Testbench ***");

    WaitForBarrier(test_done);

    std.env.stop;
  end process;

  read_p: process is
    variable addr      : std_logic_vector(6 downto 0);
    variable data      : std_logic_vector(63 downto 0);
    variable data_read : std_logic_vector(63 downto 0);
  begin
    WaitForBarrier(test_start);

    Log("*** Start of Tests (I2C) ***");

    -- PoC
    addr := "0100000";
    data := x"00_00_00_00_22_FF_AA_55";
    I2CRead(i2c_trans_io(3), addr, data_read);
    AffirmIfEqual(data_read, data, "Test failed for addr " & to_hstring(addr));

    WaitForBarrier(test_done);
    test_done <= 1;

    I2CRead(i2c_trans_io(3), addr, data_read);
    AffirmIfEqual(data_read, data, "Test failed for addr " & to_hstring(addr));

    WaitForBarrier(test_done);

    Log("*** End of Tests (I2C) ***");

    
    wait;
  end process;

end architecture;

configuration tb_i2c of dut_harness is
  for harness_arc
    for dut_test_ctrl_inst: dut_test_ctrl
      use entity work.dut_test_ctrl(tb_i2c_arc);
    end for;
  end for;
end configuration;
