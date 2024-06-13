library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.i2c_pkg.all;

library osvvm;
context osvvm.OsvvmContext;
  use osvvm.AlertLogPkg.all ;

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

  type data_t is array (integer range 0 to 63) of std_logic_vector(7 downto 0);

  function flatten(arr: data_t) return std_logic_vector is
    variable res : std_logic_vector((64*8)-1 downto 0) := (others => '0');
  begin
    for i in data_t'range loop
      res(8*(i+1)-1 downto 8*i) := arr(i);
    end loop;
    return res;
  end function;

  type I2cBitT is (I2C_VALUE, I2C_START, I2C_STOP);
  type I2cValueRec is record
    bit_type : I2cBitT;
    value    : std_logic;
  end record;

  procedure I2CReadBit(signal pins : in I2cPinoutT; variable value : out I2cValueRec) is
    variable sda_at_start : std_logic;
  begin
    wait until pins.scl = 'Z';
    sda_at_start := '1' when pins.sda = 'Z' else '0';
    wait until pins.sda'event or pins.scl = '0';
    if pins.scl = 'Z' then
      if pins.sda = '0' then
        value := (I2C_START, 'X');
        wait until pins.scl = '0';
      elsif pins.sda = 'Z' then
        value := (I2C_STOP, 'X');
      else
        Alert("I2CReadBit: SDA changed to bogus value during high SCL: " & to_string(sda_at_start) & " -> " & to_string(pins.sda));
        value := (I2C_VALUE, pins.sda);
      end if;
      
    else
      value := (I2C_VALUE, sda_at_start);
    end if;
  end procedure;

  procedure I2CReadInto(signal pins : in I2cPinoutT; variable read_data : out std_logic_vector; variable error : out boolean) is
    variable b : I2cValueRec;
  begin
    for i in read_data'range loop
      I2CReadBit(pins, b);
      if b.bit_type /= I2C_VALUE then
        Alert("I2CReadNBits: Recieved " & to_string(b.bit_type) & " but expected VALUE.");
        error := true;
        return;
      end if;
      read_data(i) := b.value;
    end loop;
  end procedure;

  procedure perform_read(
      signal   pins_io  : inout I2cPinoutT;
      variable dev_addr : out   std_logic_vector(6 downto 0);
      variable reg_addr : out   std_logic_vector(7 downto 0);
      variable data     : out   std_logic_vector(64*8-1 downto 0)
    ) is
    variable b : I2cValueRec;
    variable d: data_t;
    variable byte : std_logic_vector(7 downto 0);
    variable err : boolean;
  begin
    Log("*** Waiting for I2C start ***");
    I2CWaitForStart(pins_io);

    -- Read slave address and 0
    I2CReadInto(pins_io, dev_addr, err);
    if err then
      return;
    end if;
    I2CReadBit(pins_io, b);
    if b.bit_type /= I2C_VALUE or b.value /= '0' then
      Alert("I2CRead: Expected 0 but returned (" & to_string(b.bit_type) & ", " & to_string(b.value) & ").");
      return;
    end if; 
    I2CWriteAck(pins_io);

    -- Read register address
    I2CReadInto(pins_io, reg_addr, err);
    Log("now1" & boolean'image(err));
    if err then
      return;
    end if;
    I2CWriteAck(pins_io);
     Log("now2");
    -- Read data
    for i in d'range loop
      I2CReadInto(pins_io, byte, err);
      Log("now3" & boolean'image(err));
      if err then
        return;
      end if;
      d(i) := byte;
      I2CWriteAck(pins_io);
      data := flatten(d);
    end loop;
  end procedure;


  procedure perform_write(
      variable dev_addr : out   std_logic_vector(6 downto 0);
      variable reg_addr : out   std_logic_vector(7 downto 0);
      signal   pins  : inout I2cPinoutT;
      variable data     : out   std_logic_vector(63 downto 0)
    ) is
    variable i, j          : integer;
    variable received_stop : boolean;
  begin
    I2CWaitForStart(pins);
    --I2CReadAddress(pins, dev_addr);
    --I2CReadAddress(pins, dev_addr, true);

    -- receive the data until the stop condition
    -- send the data
    for i in data'range loop
      for j in 7 downto 0 loop
        wait until pins.scl = 'Z';
        data(i * 8 + j) := pins.sda;
        wait until pins.sda = 'Z' or pins.scl = '0';
        if pins.sda = 'Z' then
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



  timing_p: process (pins_io.scl, pins_io.sda) is
    constant LOW_TIME : time := 1.3 us;
    constant HIGH_TIME : time := 0.6 us;
    constant START_HOLD_TIME : time := 0.6 us;
    constant START_SETUP_TIME : time := 0.6 us;
    constant STOP_SETUP_TIME : time := 0.6 us;
    constant STOP_START_IDLE_TIME : time := 1.3 us;
    constant DATA_SETUP_TIME : time := 100 ns;
    variable start_cond_met : boolean := false;
    variable start_cond_time: time := 0 us;
    variable stop_cond_time: time := 0 us;
    variable data_change_met : boolean := false;
  begin
    -- CHECKS FOR SCL LOW/HIGH TIME AND DATA SETUP TIME
    if pins_io.scl'event then
      if pins_io.scl = '1' then
        AlertIfNot(pins_io.scl'last_event >= LOW_TIME, "I2C SCL LOW time of >=1.3 us was not met");
        -- if a start was currently going on but the sda had no change in the meantime,
        -- that means sda signal simply stayed low until the new rising clock edge, so start has completed
        if start_cond_met then
          start_cond_met := false;
        end if;

        if data_change_met then
          data_change_met := false;
          AlertIfNot((now - pins_io.sda'last_event) >= DATA_SETUP_TIME, "I2C DATA SETUP time of >= 100 ns was not met");
        end if;

      elsif pins_io.scl = '0' then
        AlertIfNot(pins_io.scl'last_event >= HIGH_TIME, "I2C SCL HIGH time of >=0.6 us was not met");
      end if;
    end if;

    -- CHECKS FOR START/STOP CONDITIONS
    if pins_io.sda'event then
      if pins_io.sda'last_value = '0' or pins_io.sda'last_value = '1' then
        -- ignore other kinds of changes for now
        if pins_io.scl = '1' then
          -- there is currently either a start or stop happening
          if pins_io.sda = '1' then
            -- encountered stop condition, check when the clock change was to see if setup time was met
            AlertIfNot((now - pins_io.scl'last_event) >= STOP_SETUP_TIME, "I2C STOP SETUP time of >= 0.6 us was not met");
            stop_cond_time := now;
          elsif pins_io.sda = '0' then
            -- encountered start condition
            start_cond_met := true;
            start_cond_time := now;
            AlertIfNot((now - pins_io.scl'last_event) >= START_SETUP_TIME, "I2C START SETUP time of >= 0.6 us was not met");
            -- check if the previous stop signal was more than STOP_START_IDLE_TIME
            AlertIfNot((now - stop_cond_time) >= STOP_START_IDLE_TIME, "I2C Idle time between STOP and following START of >= 1.3 us was not met");
          end if;
        elsif pins_io.scl = '0' then
           -- clock is currently low, check if there was a start going
          if start_cond_met then
            AlertIfNot((now - start_cond_time) >= START_HOLD_TIME, "I2C START HOLD time of >= 0.6 us was not met");
            start_cond_met := false;
          end if;
          data_change_met := true;
        end if;
      end if;
    end if;
  end process;

  sequencer_p: process is
    variable dev_addr : std_logic_vector(6 downto 0);
    variable reg_addr : std_logic_vector(7 downto 0);
    variable data     : std_logic_vector(64*8-1 downto 0) := (others => '0');
  begin
    pins_io.scl <= 'Z';
    pins_io.sda <= 'Z';
    wait for 0 ns;
    dispatcher_loop: loop
      WaitForTransaction(clk => clk_i, Rdy => trans_io.Rdy, Ack => trans_io.Ack);
      case trans_io.Operation is
        when WRITE_OP =>
          --perform_write(dev_addr, reg_addr, pins_io, data);
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
