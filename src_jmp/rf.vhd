library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rf is
port(
	clk, resetn, regwrite: in std_logic;
	readregister1,readregister2: in std_logic_vector(4 downto 0);
	writeregister: in std_logic_vector(4 downto 0);
	writedata: in std_logic_vector(31 downto 0);
	readdata1: out std_logic_vector(31 downto 0); 
	readdata2: out std_logic_vector(31 downto 0)
);
end rf;

architecture behavior of rf is

component registro_en is 
	generic (n:integer:=32);
	port(
	d: in std_logic_vector(n-1 downto 0);
	clk: in std_logic;
	rst: in std_logic;
	en: in std_logic;
	q: out std_logic_vector(n-1 downto 0)
);
end component;

component mux32to1 is
generic ( n : integer:=32);
	port (i0,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15,i16,i17,i18,i19,i20,i21,i22,i23,i24,i25,i26,i27,i28,i29,i30,i31: in std_logic_vector(n-1 downto 0);
		  s	    : in std_logic_vector(4 downto 0);
		  o     : out std_logic_vector(n-1 downto 0));
end component;

type out_array is array (31 downto 1) of std_logic_vector(31 downto 0);
signal regoutput:out_array;
signal regwrite_s: std_logic_vector(31 downto 1);
signal i0: std_logic_vector(31 downto 0);
begin

i0<=X"00000000";
load_p: process (regwrite, writeregister, writedata)
begin
	for i in 1 to 31 loop
		if (regwrite='1' and (writeregister=std_logic_vector(to_unsigned(i,5)))) then 
			regwrite_s(i)<='1';
		else 
			regwrite_s(i)<='0';
		end if;	
	end loop;
end process load_p;

regarray: for i in 1 to 31 generate
	reg:registro_en port map (d=>writedata,clk=>clk,rst=>resetn,en=>regwrite_s(i),q=>regoutput(i));
end generate regarray;

mux1: mux32to1 port map(i0,regoutput(1),regoutput(2),regoutput(3),regoutput(4),regoutput(5),regoutput(6),regoutput(7),regoutput(8),regoutput(9),regoutput(10),regoutput(11),regoutput(12),regoutput(13),regoutput(14),regoutput(15),regoutput(16),regoutput(17),regoutput(18),regoutput(19),regoutput(20),regoutput(21),regoutput(22),regoutput(23),regoutput(24),regoutput(25),regoutput(26),regoutput(27),regoutput(28),regoutput(29),regoutput(30),regoutput(31),readregister1,readdata1);
mux2: mux32to1 port map(i0,regoutput(1),regoutput(2),regoutput(3),regoutput(4),regoutput(5),regoutput(6),regoutput(7),regoutput(8),regoutput(9),regoutput(10),regoutput(11),regoutput(12),regoutput(13),regoutput(14),regoutput(15),regoutput(16),regoutput(17),regoutput(18),regoutput(19),regoutput(20),regoutput(21),regoutput(22),regoutput(23),regoutput(24),regoutput(25),regoutput(26),regoutput(27),regoutput(28),regoutput(29),regoutput(30),regoutput(31),readregister2,readdata2);

end behavior;
