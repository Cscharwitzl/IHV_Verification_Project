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

  procedure I2CWrite(signal trans: inout AddressBusRecType; address, data: std_logic_vector);
  procedure I2CRead (signal trans: inout AddressBusRecType; address: std_logic_vector; variable read_data: out std_logic_vector);

end package;

package body i2c_pkg is

  procedure I2CWrite(signal trans: inout AddressBusRecType; address, data: in std_logic_vector) is
  begin
    Write(trans, address, data);
  end procedure;

  procedure I2CRead (signal trans: inout AddressBusRecType; address: in std_logic_vector; variable read_data: out std_logic_vector) is
  begin
    Read(trans, address, read_data);
  end procedure;

end package body;