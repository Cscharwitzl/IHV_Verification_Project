library common_lib;
context common_lib.common_context;
use work.avmm_pkg.all;

architecture tb_reset_arc of dut_test_ctrl is
begin

  CreateClock(clk_o, 10 ns);
  
  stimuli_p: process is
    constant controlreg_re: std_logic_vector(31 downto 0) := x"00000000";
    constant statusreg_re: std_logic_vector(31 downto 0) := x"00000000";
    constant busreg_re: std_logic_vector(31 downto 0) := x"00000001";

    variable data_read: std_logic_vector(31 downto 0) := (others => '0');
  begin
    Log("*** Start of Testbench reset ***");

    rst_o <= '1';
    WaitForClock(clk_o,3);
    rst_o <= '0';

    --T-002
    Log("* testcase 2");
    AvmmWrite(avmm_trans_io,x"00",x"FFFFFFFE","1111");
    AvmmWrite(avmm_trans_io,x"01",x"FFFFFFFF","1111");
    AvmmWrite(avmm_trans_io,x"02",x"FFFFFFFE","1111");
    AvmmRead(avmm_trans_io,x"00","1111",data_read);

    rst_o <= '1';
    WaitForClock(clk_o,2);
    rst_o <= '0';
    AvmmRead(avmm_trans_io,x"00","1111",data_read);
    AffirmIfEqual(data_read,controlreg_re, "Control Reg reste values are wrong (hard-reset)");
    AvmmRead(avmm_trans_io,x"01","1111",data_read);
    AffirmIfEqual(data_read,statusreg_re, "Status Reg reste values are wrong  (hard-reset)");
    AvmmRead(avmm_trans_io,x"02","1111",data_read);
    AffirmIfEqual(data_read,busreg_re, "Bus Enable Reg reste values are wrong  (hard-reset)");


    --T-003
    Log("* testcase 3");
    AvmmWrite(avmm_trans_io,x"00",x"FFFFFFFE","1111");
    AvmmWrite(avmm_trans_io,x"01",x"FFFFFFFF","1111");
    AvmmWrite(avmm_trans_io,x"02",x"FFFFFFFE","1111");

    AvmmWrite(avmm_trans_io,x"00",x"FFFFFFFF","1111");
    WaitForClock(clk_o,2);
    AvmmRead(avmm_trans_io,x"00","1111",data_read);
    AffirmIfEqual(data_read,controlreg_re, "Control Reg reste values are wrong  (soft-reset)");
    AvmmRead(avmm_trans_io,x"01","1111",data_read);
    AffirmIfEqual(data_read,statusreg_re, "Status Reg reste values are wrong  (soft-reset)");
    AvmmRead(avmm_trans_io,x"02","1111",data_read);
    AffirmIfEqual(data_read,busreg_re, "Bus Enable Reg reste values are wrong  (soft-reset)");

    Log("*** End of Testbench reset ***");

    std.env.stop;
  end process;
  
end architecture;

configuration tb_reset of dut_harness is
  for harness_arc
    for dut_test_ctrl_inst: dut_test_ctrl
      use entity work.dut_test_ctrl(tb_reset_arc) ; 
    end for; 
  end for; 
end configuration;