library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm_common;
  context osvvm_common.OsvvmCommonContext;

package i2c_pkg is
  
  type I2cPinoutT is record
    scl: std_logic;
    sda: std_logic;
  end record;

  type I2cPinoutTArray is array(natural range<>) of I2cPinoutT;
  type AddressBusRecTypeArray is array(natural range<>) of AddressBusRecType(Address(5 downto 0), DataToModel(31 downto 0), DataFromModel(31 downto 0));

  procedure I2CReadBit(signal pins: in I2cPinoutT; variable value: out std_logic);
  procedure I2CReadAck(signal pins: in I2cPinoutT; variable was_ack: out boolean);
  procedure I2CWriteAck(signal pins: inout I2cPinoutT);

  procedure I2CWaitForStart(signal pins: in I2cPinoutT);
  procedure I2CReadAddress(signal pins: in I2cPinoutT; variable addr: out std_logic_vector);
  procedure I2CReadDataByte(signal pins: in I2cPinoutT; variable data: out std_logic_vector);

  procedure I2CWrite(signal trans: inout AddressBusRecType; address, data: std_logic_vector);
  procedure I2CRead (signal trans: inout AddressBusRecType; address: std_logic_vector; variable read_data: out std_logic_vector);

end package;

package body i2c_pkg is

  procedure I2CReadBit(signal pins: in I2cPinoutT; variable value: out std_logic) is
  begin
    wait until rising_edge(pins.scl);
    value := pins.sda;
  end procedure;

  procedure I2CReadAck(signal pins: inout I2cPinoutT; variable was_ack: out boolean) is
  begin
    wait until rising_edge(pins.scl);
    pins.sda <= 'H';
    wait until pins.sda = '0' or falling_edge(pins.scl);
    was_ack := TRUE when pins.sda = '0' else FALSE;
  end procedure;

  procedure I2CWriteAck(signal pins: inout I2cPinoutT) is
  begin
    wait until rising_edge(pins.scl);
    pins.sda <= '0';
  end procedure;

  procedure I2CWaitForStart(signal pins: in I2cPinoutT) is
  begin
    AffirmIfEqual(true, true, "I2C Specification violated. (Wrong pin state before START)"); -- TODO: enter correct pin state in assertion
    wait until pins.scl = '1' and falling_edge(pins.sda);
  end procedure;

  procedure I2CReadAddress(signal pins: in I2cPinoutT; variable addr: out std_logic_vector) is
    variable value: std_logic;
  begin
    for i in addr'range loop
      I2CReadBit(pins, value);
      addr(i) <= value;
    end loop;
    I2CReadBit(pins, value);
    AffirmIfEqual(value, 0, "Did not send 0 after address.");
    I2CWriteAck(pins);
  end procedure;

  procedure I2CReadDataByte(signal pins: in I2cPinoutT; variable data: out std_logic_vector) is
    variable value: std_logic;
  begin
    for i in addr'range loop
      I2CReadBit(pins, value);
      data(i) <= value;
    end loop;
    I2CWriteAck(pins);
  end procedure;

  procedure I2CWrite(signal trans: inout AddressBusRecType; address, data: in std_logic_vector) is
  begin
    Write(trans, address, data);
  end procedure;

  procedure I2CRead (signal trans: inout AddressBusRecType; address: in std_logic_vector; variable read_data: out std_logic_vector) is
  begin
    Read(trans, address, read_data);
  end procedure;

end package body;