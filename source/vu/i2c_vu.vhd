library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.i2c_pkg.all;

library osvvm;
context osvvm.OsvvmContext;

library osvvm_common;
context osvvm_common.OsvvmCommonContext;

entity i2c_vu is
  port (
    trans_io: inout AddressBusRecType;
    clk_i   : in    std_logic;
    pins_io : inout I2cPinoutT
  );
end entity;

architecture rtl of i2c_vu is
begin

  --------------------------
  -- This probably wont work
  --------------------------

  slave_rx_p : process is -- wait for signals from master indicating a r/w
  begin
    -- wait for i2c start condition
    wait until pins_io.scl and rising_edge(pins_io.sda);
    -- receive data

    -- wait for stop condition

  end process;

  sequencer_p: process is
  begin

    -- apply default values
    pins_io.scl <= 'Z'; -- When no bus transfer is ongoing, SCL/SDA <= high Z
    pins_io.sda <= 'Z';
    --
    wait for 0 ns;

    dispatcher_loop: loop
      -- WaitForTransaction(clk => clk_i, Rdy => trans_io.Rdy, Ack => trans_io.Ack);
      case trans_io.Operation is

        when WRITE_OP =>
          -- start condition
          pins_io.sda <= '0';
          wait for 0.6 us;

          -- data loop
          for value in trans_io.Address'range loop
            pins_io.sda <= '0';
          end loop;

          -- stop condition
          pins_io.scl <= '1';
          wait for 0.6 us;
          pins_io.sda <= '1';
        -- WRITE_OP END 

        when READ_OP =>
        -- READ_OP END

        when others =>

      end case;
    end loop;

  end process;

end architecture;
