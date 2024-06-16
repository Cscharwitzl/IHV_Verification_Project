library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm;
context osvvm.OsvvmContext;

library osvvm_common;
context osvvm_common.OsvvmCommonContext;

package avmm_pkg is

  type AvmmPinoutT is record
    address    : std_logic_vector;
    writedata  : std_logic_vector;
    readdata   : std_logic_vector;
    byteenable : std_logic_vector;
    read       : std_logic;
    write      : std_logic;
  end record;

  type DataRegArrayT is array (natural range <>) of std_logic_vector(31 downto 0);

  procedure AvmmWrite(signal trans : inout AddressBusRecType; addr, data, byte_enable : std_logic_vector);
  procedure AvmmRead(signal trans : inout AddressBusRecType; addr, byte_enable : std_logic_vector; variable read_data : out std_logic_vector);
  procedure startI2CTransfereInAVMM(
    signal trans       : inout AddressBusRecType;
           op          : in    std_logic;
           bus_enable  : in    std_logic_vector(3 downto 0);
           reg_addr    : in    std_logic_vector(7 downto 0);
           target_addr : in    std_logic_vector(6 downto 0);
           data_len    : in    integer;
           read_data   : in    DataRegArrayT(0 to 15) := (others => (others => '0')));
  procedure readDataRegs(signal trans : inout AddressBusRecType; data : out DataRegArrayT);
  function DataRegArr_to_slv(datareg : DataRegArrayT) return std_logic_vector;
  procedure waitForFlags(signal trans : inout AddressBusRecType; addr : std_logic_vector; bitmask : std_logic_vector(31 downto 0); value : std_logic; maxNumTries : integer);

end package;

package body avmm_pkg is

  procedure AvmmWrite(signal trans : inout AddressBusRecType; addr, data, byte_enable : std_logic_vector) is
  begin
    trans.IntToModel <= to_integer(unsigned(byte_enable));
    Write(trans, addr, data);
  end procedure;

  procedure AvmmRead(signal trans : inout AddressBusRecType; addr, byte_enable : std_logic_vector; variable read_data : out std_logic_vector) is
  begin
    trans.IntToModel <= to_integer(unsigned(byte_enable));
    Read(trans, addr, read_data);
  end procedure;

  procedure startI2CTransfereInAVMM(
      signal trans       : inout AddressBusRecType;
             op          : in    std_logic;
             bus_enable  : in    std_logic_vector(3 downto 0);
             reg_addr    : in    std_logic_vector(7 downto 0);
             target_addr : in    std_logic_vector(6 downto 0);
             data_len    : in    integer;
             read_data   : in    DataRegArrayT(0 to 15) := (others => (others => '0'))) is
    variable reg : std_logic_vector(31 downto 0) := (others => '0');
  begin

    --select I2C bus
    AvmmWrite(trans, "000010", x"0000000" & bus_enable, "0001");

    --write data
    for i in read_data'range loop
      AvmmWrite(trans, std_logic_vector(to_unsigned(i + 16, 6)), read_data(i), "1111");
    end loop;

    --write controlreg and start
    reg(31) := '1';
    reg(29 downto 24) := std_logic_vector(to_unsigned(data_len - 1, 6));
    reg(23 downto 16) := reg_addr;
    reg(11 downto 5) := target_addr;
    reg(4) := op;
    reg(1) := '1';
    reg(0) := '0';
    AvmmWrite(trans, x"00", reg, "1111");

  end procedure;

  procedure readDataRegs(signal trans : inout AddressBusRecType; data : out DataRegArrayT) is
    variable data_reg : std_logic_vector(31 downto 0) := (others => '0');
  begin
    for i in data'range loop
      AvmmRead(trans, std_logic_vector(to_unsigned(i + 16, 6)), "1111", data_reg);
      data(i) := data_reg;
    end loop;
  end procedure;

  function DataRegArr_to_slv(datareg : DataRegArrayT) return std_logic_vector is
    variable slv : std_logic_vector(64 * 8 - 1 downto 0);
  begin
    for i in datareg'range loop
      slv((i + 1) * 32 - 1 downto i * 32) := datareg(i);
    end loop;

    return slv;
  end function;

  procedure waitForFlags(signal trans : inout AddressBusRecType; addr : std_logic_vector; bitmask : std_logic_vector(31 downto 0); value : std_logic; maxNumTries : integer) is
    variable read_data : std_logic_vector(31 downto 0);
  begin
    for i in 0 to maxNumTries - 1 loop
      AvmmRead(trans, addr, "1111", read_data);
      if (or(read_data and bitmask)) = value then
        return;
      end if;
    end loop;
    Alert("Flag was not set during " & integer'image(maxNumTries) & " numbers of tries");
  end procedure;

end package body;
