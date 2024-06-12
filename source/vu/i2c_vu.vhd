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
    trans_io : inout AddressBusRecType;
    clk_i    : in    std_logic;
    pins_io  : inout I2cPinoutT
  );
end entity;

architecture rtl of i2c_vu is

  -- procedure perform_read(
  --     variable dev_addr : out   std_logic_vector(6 downto 0);
  --     variable reg_addr : out   std_logic_vector(6 downto 0);
  --     signal pins_io  : inout I2cPinoutT;
  --     variable data     : in    std_logic_vector(63 downto 0)
  --   ) is
  --   variable i, j          : integer;
  --   variable received_nack : boolean;
  -- begin
  --   I2CWaitForStart(pins_io);
  --   I2CReadAddress(pins_io, dev_addr);
  --   I2CReadAddress(pins_io, reg_addr, true);
  --   I2CWaitForStart(pins_io);
  --   -- master sends the slave address again TODO make sure its the same as last time
  --   I2CReadAddress(pins_io, dev_addr, expected_suffix => '1');
  --   -- send the data
  --   for i in data'range loop
  --     for j in 7 downto 0 loop
  --       wait until not pins_io.scl;
  --       pins_io.sda <= data(i * 8 + j);
  --       wait until rising_edge(pins_io.scl);
  --     end loop;
  --     if pins_io.sda = '1' then -- NACK
  --       received_nack := true;
  --       exit;
  --     end if;
  --   end loop;
  --   if not received_nack then
  --     -- something went wrong
  --     -- device tried to read more then 64 bits which is not allowed
  --     Alert("Device tried to read more then 64 bits");
  --   end if;
  --   I2CWaitForStop(pins_io);
  -- end procedure;
  procedure perform_read(
      signal   pins_io  : inout I2cPinoutT;
      variable dev_addr : out   std_logic_vector(6 downto 0);
      variable reg_addr : out   std_logic_vector(6 downto 0);
      variable data     : out   std_logic_vector(63 downto 0)
    ) is
    variable byte : std_logic_vector(7 downto 0);
    variable stop : boolean;
  begin
    Log("*** Waiting for I2C start ***");
    I2CWaitForStart(pins_io);
    I2CReadAddress(pins_io, dev_addr);
    I2CReadAddress(pins_io, reg_addr, true);

    -- read data
    for i in (data'length / 8) - 1 downto 0 loop
      I2CReadNextByte(pins_io, byte, stop);
      if stop then
        exit;
      end if;
      data(i * 8 + 7 downto i * 8) := byte;
    end loop;

  end procedure;

  procedure perform_write(
      variable dev_addr : out   std_logic_vector(6 downto 0);
      variable reg_addr : out   std_logic_vector(6 downto 0);
      signal   pins_io  : inout I2cPinoutT;
      variable data     : out   std_logic_vector(63 downto 0)
    ) is
    variable i, j          : integer;
    variable received_stop : boolean;
  begin
    I2CWaitForStart(pins_io);
    I2CReadAddress(pins_io, dev_addr);
    I2CReadAddress(pins_io, dev_addr, true);

    -- receive the data until the stop condition
    -- send the data
    for i in data'range loop
      for j in 7 downto 0 loop
        wait until rising_edge(pins_io.scl);
        data(i * 8 + j) := pins_io.sda;
        wait until rising_edge(pins_io.sda) or falling_edge(pins_io.scl);
        if rising_edge(pins_io.sda) then
          received_stop := true;
          exit;
        end if;
      end loop;
      if received_stop then
        exit;
      end if;
    end loop;
  end procedure;

begin

  sequencer_p: process is
    variable dev_addr : std_logic_vector(6 downto 0);
    variable reg_addr : std_logic_vector(6 downto 0);
    variable data     : std_logic_vector(63 downto 0);
  begin
    wait for 0 ns;
    dispatcher_loop: loop
      WaitForTransaction(clk => clk_i, Rdy => trans_io.Rdy, Ack => trans_io.Ack);
      case trans_io.Operation is
        when WRITE_OP =>
          perform_write(dev_addr, reg_addr, pins_io, data);
          trans_io.DataFromModel <= std_logic_vector_max_c(data);
          -- WRITE_OP END 
        when READ_OP =>
          Log("*** Start of I2C Read Transaction ***");
          perform_read(pins_io, dev_addr, reg_addr, data);
          trans_io.DataFromModel <= SafeResize(data, trans_io.DataFromModel'length);
          trans_io.Address <= SafeResize(dev_addr & reg_addr, trans_io.Address'length);
          Log("*** End of I2C Read Transaction ***");
          -- READ_OP END
        when others =>
          Alert("Unimplemented Transaction", FAILURE);
      end case;
    end loop;
  end process;

end architecture;
