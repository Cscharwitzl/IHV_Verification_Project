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
  procedure send_ack is
  begin
    wait until not pins_io.scl;
    pins_io.sda <= '0';
  end procedure;

  procedure read(
    signal dev_addr : out std_logic_vector(6 downto 0);
    signal reg_addr : out std_logic_vector(6 downto 0);
    signal data : in std_logic_vector(63 downto 0)
  ) is
  variable i, j : integer;
  variable received_nack : boolean;
  begin
    -- wait for i2c start condition
    wait until pins_io.scl and falling_edge(pins_io.sda);

    i := 0;
    read_dev_addr_loop: loop -- read device address
      wait until rising_edge(pins_io.scl);
      dev_addr(i) <= pins_io.sda;
      i := i + 1;
      if i = 7 then
        exit read_dev_addr_loop;
      end if;
    end loop;

    wait until rising_edge(pins_io.scl);
    -- TODO test if pin_io.sda is low as per requirements

    send_ack;

    i := 0;
    read_reg_addr_loop: loop -- read register address
      wait until rising_edge(pins_io.scl);
      reg_addr(i) <= pins_io.sda;
      i := i + 1;
      if i = 7 then
        exit read_reg_addr_loop;
      end if;
    end loop;

    send_ack;

    wait until pins_io.scl and falling_edge(pins_io.sda);
    
    -- master sends the slave address again (TODO make sure its the same as the previous?)

    i := 0;
    read_reg2_loop: loop -- read data
      wait until rising_edge(pins_io.scl);
      reg_addr(i) <= pins_io.sda;
      i := i + 1;
      if i = 7 then
        exit read_reg2_loop;
      end if;
    end loop;

    wait until rising_edge(pins_io.scl);
    -- TODO test if pin_io.sda is high as per requirements

    send_ack;

    -- send the data
    for i in data'range loop
      for j in 7 downto 0 loop
        wait until not pins_io.scl;
        pins_io.sda <= data(i*8+j);
        wait until rising_edge(pins_io.scl);
      end loop;
      if pins_io.sda = '1' then -- NACK
        received_nack := true;
        exit;
      end if;
    end loop;

    if not received_nack then
      -- something went wrong
      -- device tried to read more then 64 bits which is not allowed
      Alert("Device tried to read more then 64 bits");
    end if;

    -- wait for stop condition
    wait until pins_io.scl and rising_edge(pins_io.sda);

  end procedure;
begin

  --------------------------
  -- This probably wont work
  --------------------------

  sequencer_p: process is
  variable dev_addr : std_logic_vector(6 downto 0);
  variable reg_addr : std_logic_vector(6 downto 0);
  begin

    -- apply default values
    pins_io.scl <= 'Z'; -- When no bus transfer is ongoing, SCL/SDA <= high Z
    pins_io.sda <= 'Z';
    --
    wait for 0 ns;

    dispatcher_loop: loop
      WaitForTransaction(clk => clk_i, Rdy => trans_io.Rdy, Ack => trans_io.Ack);
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
          read(dev_addr, reg_addr, trans_io.DataToModel);
        -- READ_OP END

        when others =>

      end case;
    end loop;

  end process;

end architecture;
