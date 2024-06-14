library common_lib;
context common_lib.common_context;
use work.avmm_pkg.all;
use osvvm.AlertLogPkg.all ;

architecture tb_avmm_arc of dut_test_ctrl is
  
begin

  CreateClock(clk_o, 10 ns);
  CreateReset(rst_o, '1', clk_o, 100 ns, 0 ns);
  
  stimuli_p: process is
    variable data_read : std_logic_vector(31 downto 0);
    variable test_data : std_logic_vector(31 downto 0);
    variable byte_en : std_logic_vector(3 downto 0);
    variable addr : std_logic_vector(5 downto 0);
    variable bitmask : std_logic_vector(31 downto 0);
  begin

    wait until rst_o = '0';
    
    --T-015 and T-016
    test_data := x"AAAAAAAA";
    byte_en := "1111";
    addr := "010000";
    AvmmWrite(avmm_trans_io,addr,test_data,byte_en);
    AvmmRead(avmm_trans_io,addr,byte_en,data_read);
    AffirmIfEqual(data_read,test_data,"Test failed for addr " & to_hstring(addr));

    --T-051 and T-052
    test_data := x"55555555";
    byte_en := "1111";
    addr := "010000";
    AvmmWrite(avmm_trans_io,addr,test_data,byte_en);
    AvmmRead(avmm_trans_io,addr,byte_en,data_read);
    AffirmIfEqual(data_read,test_data,"Test failed for addr " & to_hstring(addr));

    --T017 and T-018
    test_data := x"AAAAAAAA";
    byte_en := "1111";
    addr := "011111";
    AvmmWrite(avmm_trans_io,addr,test_data,byte_en);
    AvmmRead(avmm_trans_io,addr,byte_en,data_read);
    AffirmIfEqual(data_read,test_data,"Test failed for addr " & to_hstring(addr));

    --T-053 and T-054
    test_data := x"55555555";
    byte_en := "1111";
    addr := "011111";
    AvmmWrite(avmm_trans_io,addr,test_data,byte_en);
    AvmmRead(avmm_trans_io,addr,byte_en,data_read);
    AffirmIfEqual(data_read,test_data,"Test failed for addr " & to_hstring(addr));

    --T-055 
    test_data := x"FFFFFFFF";
    byte_en := "0001";
    addr := "010000";
    AvmmWrite(avmm_trans_io,addr,x"00000000","1111");
    AvmmWrite(avmm_trans_io,addr,test_data,byte_en);
    AvmmRead(avmm_trans_io,addr,byte_en,data_read);
    AffirmIfEqual(data_read,(test_data and x"000000FF"),"Test failed for addr " & to_hstring(addr));

    --T-056
    test_data := x"FFFFFFFF";
    byte_en := "0010";
    addr := "010000";
    AvmmWrite(avmm_trans_io,addr,x"00000000","1111");
    AvmmWrite(avmm_trans_io,addr,test_data,byte_en);
    AvmmRead(avmm_trans_io,addr,byte_en,data_read);
    AffirmIfEqual(data_read,(test_data and x"0000FF00"),"Test failed for addr " & to_hstring(addr));

    --T-057
    test_data := x"FFFFFFFF";
    byte_en := "0100";
    addr := "010000";
    AvmmWrite(avmm_trans_io,addr,x"00000000","1111");
    AvmmWrite(avmm_trans_io,addr,test_data,byte_en);
    AvmmRead(avmm_trans_io,addr,byte_en,data_read);
    AffirmIfEqual(data_read,(test_data and x"00FF0000"),"Test failed for addr " & to_hstring(addr));

    --T-058
    test_data := x"FFFFFFFF";
    byte_en := "1000";
    addr := "010000";
    AvmmWrite(avmm_trans_io,addr,x"00000000","1111");
    AvmmWrite(avmm_trans_io,addr,test_data,byte_en);
    AvmmRead(avmm_trans_io,addr,byte_en,data_read);
    AffirmIfEqual(data_read,(test_data and x"FF000000"),"Test failed for addr " & to_hstring(addr));

    --T-011 and T-012
    test_data := x"55555555";
    byte_en := "1111";
    addr := "000001";
    bitmask := x"00000003";
    AvmmWrite(avmm_trans_io,addr,x"00000000","1111");
    AvmmWrite(avmm_trans_io,addr,test_data,byte_en);
    AvmmRead(avmm_trans_io,addr,byte_en,data_read);
    AffirmIfEqual(data_read,(test_data and bitmask) or (data_read and not bitmask),"Test failed for addr " & to_hstring(addr));

    --T-013 and T-014
    test_data := x"55555555";
    byte_en := "1111";
    addr := "000010";
    bitmask := x"00000007";
    AvmmWrite(avmm_trans_io,addr,x"00000000","1111");
    AvmmWrite(avmm_trans_io,addr,test_data,byte_en);
    AvmmRead(avmm_trans_io,addr,byte_en,data_read);
    AffirmIfEqual(data_read,(test_data and bitmask) or (data_read and not bitmask),"Test failed for addr " & to_hstring(addr));

    --T-009 and T-010
    test_data := x"55555555";
    byte_en := "1111";
    addr := "000000";
    bitmask := "10111111111111110000111111110011";
    AvmmWrite(avmm_trans_io,addr,x"00000000","1111");
    AvmmWrite(avmm_trans_io,addr,test_data,byte_en);
    AvmmRead(avmm_trans_io,addr,byte_en,data_read);
    AffirmIfEqual(data_read,(test_data and bitmask) or (data_read and not bitmask),"Test failed for addr " & to_hstring(addr));

    std.env.stop;

  end process;
  
end architecture;

configuration tb_avmm of dut_harness is
  for harness_arc
    for dut_test_ctrl_inst: dut_test_ctrl
      use entity work.dut_test_ctrl(tb_avmm_arc) ; 
    end for; 
  end for; 
end configuration;