library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm_common;
context osvvm_common.OsvvmCommonContext;
library osvvm;
context osvvm.OsvvmContext;
use osvvm.AlertLogPkg.all;

package i2c_pkg is

  type I2cPinoutT is record
    scl : std_logic;
    sda : std_logic;
  end record;

  type I2cPinoutTArray is array (natural range <>) of I2cPinoutT;
  type AddressBusRecTypeArray is array (natural range <>) of AddressBusRecType(Address(6 downto 0), DataToModel(63 downto 0), DataFromModel(63 downto 0));

  procedure I2CReadAck(signal pins : inout I2cPinoutT; variable was_ack : out boolean);
  procedure I2CWriteAck(signal pins : inout I2cPinoutT);

  procedure I2CWaitForStart(signal pins : in I2cPinoutT); -- to deprecate
  procedure I2CWaitForStop(signal pins : in I2cPinoutT);

  procedure I2CWrite(signal trans : inout AddressBusRecType; address, data : std_logic_vector);
  procedure I2CRead(signal trans : inout AddressBusRecType; address : std_logic_vector; variable read_data : out std_logic_vector);

end package;

package body i2c_pkg is

  procedure I2CReadAck(signal pins : inout I2cPinoutT; variable was_ack : out boolean) is
  begin
    pins.sda <= 'H';
    wait until rising_edge(pins.scl);
    was_ack := TRUE when pins.sda = '0' else FALSE;
  end procedure;

  procedure I2CWriteAck(signal pins : inout I2cPinoutT) is
  begin
    pins.sda <= '0';
    wait until pins.scl = 'Z';
    wait until pins.scl = '0';
    pins.sda <= 'Z';
  end procedure;

  procedure I2CWaitForStart(signal pins : in I2cPinoutT) is
  begin
    AffirmIfEqual(pins.scl, 'Z', "I2C Specification violated. (Wrong pin state before START)"); -- TODO: enter correct pin state in assertion
    AffirmIfEqual(pins.sda, 'Z', "I2C Specification violated. (Wrong pin state before START)"); -- TODO: enter correct pin state in assertion
    wait until pins.sda = '0';
  end procedure;

  procedure I2CWaitForStop(signal pins : in I2cPinoutT) is
  begin
    AffirmIfEqual(true, true, "I2C Specification violated. (Wrong pin state before START)"); -- TODO: enter correct pin state in assertion
    wait until pins.scl = 'Z' and pins.sda = 'Z';
  end procedure;

  procedure I2CWrite(signal trans : inout AddressBusRecType; address, data : in std_logic_vector) is
  begin
    Write(trans, address, data);
  end procedure;

  procedure I2CRead(signal trans : inout AddressBusRecType; address : in std_logic_vector; variable read_data : out std_logic_vector) is
  begin
    Read(trans, address, read_data);
  end procedure;

end package body;
