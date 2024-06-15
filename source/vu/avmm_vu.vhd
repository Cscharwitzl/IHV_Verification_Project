library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.avmm_pkg.all;

library osvvm;
context osvvm.OsvvmContext;

library osvvm_common;
context osvvm_common.OsvvmCommonContext;

entity avmm_vu is
  port (
    trans_io: inout AddressBusRecType;
    clk_i   : in    std_logic;
    pins_io : inout AvmmPinoutT
  );
end entity;

architecture rtl of avmm_vu is

  signal lastclk : time;

begin
  sequencer_p: process is
  begin
    -- apply default values to the pins
    pins_io.address <= (pins_io.address'range => '0');
    pins_io.writedata <= (pins_io.writedata'range => '0');
    pins_io.byteenable <= (pins_io.byteenable'range => '0');
    pins_io.read <= '0';
    pins_io.write <= '0';

    wait for 0 ns;

    dispatcher_loop: loop
      WaitForTransaction(clk => clk_i, Rdy => trans_io.Rdy, Ack => trans_io.Ack);
      case trans_io.Operation is

        when WRITE_OP =>
          pins_io.address <= SafeResize(trans_io.Address, pins_io.address'length);
          pins_io.writedata <= SafeResize(trans_io.DataToModel, pins_io.writedata'length);
          pins_io.byteenable <= std_logic_vector(to_unsigned(trans_io.IntToModel, pins_io.byteenable'length));
          pins_io.read <= '0';
          pins_io.write <= '1';
          WaitForClock(clk_i);
          pins_io.write <= '0';
        -- WRITE_OP END

        when READ_OP =>
          pins_io.address <= SafeResize(trans_io.Address, pins_io.address'length);
          pins_io.writedata <= (pins_io.writedata'range => '0');
          pins_io.byteenable <= std_logic_vector(to_unsigned(trans_io.IntToModel, pins_io.byteenable'length));
          pins_io.read <= '1';
          pins_io.write <= '0';
          WaitForClock(clk_i, 2);
          trans_io.DataFromModel <= SafeResize(pins_io.readdata, trans_io.DataFromModel'length);
          pins_io.read <= '0';
        -- READ_OP END

        when others =>
          Alert("Unimplemented Transaction", FAILURE);
          
      end case;
    end loop;
  end process;

  lastclk <= now when rising_edge(clk_i) else lastclk;

  check_sync : process is
  begin
    loop
      wait on pins_io.readdata;
      AffirmIfEqual(now,lastclk,"readdate changed not synchronous to clock");
    end loop;
  end process;

end architecture;
