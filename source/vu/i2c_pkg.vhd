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

  subtype I2cDataACKsT is std_logic_vector(63 downto 0);
  subtype I2cAddressBusRecT is AddressBusRecType (
      Address(0 downto 0),
      DataFromModel(7 + 8 + 64 * 8 - 1 downto 0), -- addr, reg_add, data(64*8-1 downto 0)
      DataToModel(3 + 64 * (8+1) - 1 downto 0) -- addr_ack, reg_ack, sec_addr_ack, data_acks(63 downto 0), data(64*8-1 downto 0)
  );

  type I2cPinoutTArray is array (natural range <>) of I2cPinoutT;
  type AddressBusRecTypeArray is array (natural range <>) of I2cAddressBusRecT;

  procedure I2CWrite(signal trans : inout I2cAddressBusRecT; data : std_logic_vector; data_length : integer; addr_ack, reg_ack, sec_addr_ack : in std_logic);
  procedure I2CWrite(signal trans : inout I2cAddressBusRecT; data : std_logic_vector; data_length : integer);
  procedure I2CRead(signal trans : inout I2cAddressBusRecT; variable read_data : out std_logic_vector; data_length : integer; addr_ack, reg_ack : in std_logic; data_acks : in I2cDataACKsT);
  procedure I2CRead(signal trans : inout I2cAddressBusRecT; variable read_data : out std_logic_vector; data_length : integer);

end package;

package body i2c_pkg is

  procedure I2CWrite(signal trans : inout I2cAddressBusRecT; data : std_logic_vector; data_length : integer; addr_ack, reg_ack, sec_addr_ack : in std_logic) is
  begin
    trans.IntToModel <= data_length;
    trans.DataToModel <= SafeResize(addr_ack & reg_ack & sec_addr_ack & (I2cDataACKsT'range => '0') & data, trans.DataToModel'length);
    Write(trans, "", data);
  end procedure;

  procedure I2CWrite(signal trans : inout I2cAddressBusRecT; data : std_logic_vector; data_length : integer) is
  begin
    I2CWrite(trans, data, data_length, '0', '0', '0');
  end procedure;

  procedure I2CRead(signal trans : inout I2cAddressBusRecT; variable read_data : out std_logic_vector; data_length : integer; addr_ack, reg_ack : in std_logic; data_acks : in I2cDataACKsT) is
  begin
    trans.IntToModel <= data_length;
    trans.DataToModel <= SafeResize(addr_ack & reg_ack & '0' & data_acks, trans.DataToModel'length);
    Read(trans, "", read_data);
  end procedure;

  procedure I2CRead(signal trans : inout I2cAddressBusRecT; variable read_data : out std_logic_vector; data_length : integer) is
  begin
    I2CRead(trans, read_data, data_length, '0', '0', (others => '0'));
  end procedure;

end package body;
