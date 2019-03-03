library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mips is
end tb_mips;

Architecture behavioral of tb_mips is
component MIPS is
	port(
			clk: in std_logic;
			RESETn: in std_logic;
			instruction: in std_logic_vector(31 downto 0);
			DATA_out: in std_logic_vector(31 downto 0);
			addrINSTRUCTION: out std_logic_vector(31 downto 0);
			DATA_ADDR: out std_logic_vector(31 downto 0);
			WRITE_DATA: out std_logic_vector(31 downto 0);
			MemWrite2,MemRead2:	out std_logic
	);
end component;
signal clk, RESETn, MemWrite2, MemRead2: std_logic;
signal instruction, DATA_out, addrINSTRUCTION, DATA_ADDR, WRITE_DATA: std_logic_vector(31 downto 0);

begin

DUT: MIPS port map (clk,RESETn,instruction,DATA_out,addrINSTRUCTION,DATA_ADDR,WRITE_DATA,MemWrite2,MemRead2);

clock: process
begin
clk <= '0';
wait for 10 ns;
clk <= '1';
wait for 10 ns;
end process;

rst: process
begin
RESETn<='0';
wait for 32 ns;
RESETn<='1';
wait;
end process;

data_gen: process
begin
-- start filling rf
	wait for 40 ns;
	DATA_out   <=X"00000000";
	instruction<=X"2001FFFF";
	wait for 20 ns;
	instruction<=X"20020001";
	wait for 20 ns;
	instruction<=X"2003FFFE";
	wait for 20 ns;
	instruction<=X"20040002";
	wait for 20 ns;
	instruction<=X"2005FFFD";
	wait for 20 ns;
	instruction<=X"20060003";
	wait for 20 ns;
	instruction<=X"2007FFFC";
	wait for 20 ns;
	instruction<=X"20080004";
	wait for 20 ns;
	instruction<=X"2009FFFB";
	wait for 20 ns;
	instruction<=X"200A0005";
	wait for 20 ns;
	instruction<=X"200BFFFA";
	wait for 20 ns;
	instruction<=X"200C0006";
	wait for 20 ns;
	instruction<=X"200DFFF9";
	wait for 20 ns;
	instruction<=X"200E0007";
	wait for 20 ns;
	instruction<=X"200FFFF8";
	wait for 20 ns;
	instruction<=X"20100008";
	wait for 20 ns;
	instruction<=X"2011FFF7";
	wait for 20 ns;
	instruction<=X"20120009";
	wait for 20 ns;
	instruction<=X"2013FFF6";
	wait for 20 ns;
	instruction<=X"2014000A";
-- filled up to 20, now starting ops
	wait for 20 ns;
	instruction<=X"0022A820"; --add
	wait for 20 ns;
	instruction<=X"00C7B026"; --xor
	wait for 20 ns;
	instruction<=X"35DA000B"; --ori
	wait for 20 ns;
	instruction<=X"0A36B4AD"; --jmp to 37139629		
	wait for 20 ns;
	instruction<=X"0260B883"; --sra
	wait for 20 ns;
	instruction<=X"010AC02A"; --slt		
	wait for 20 ns;
	instruction<=X"082394F2"; --jmp to 2331890	
	wait for 20 ns;
	instruction<=X"31D9000B"; --andi
	wait for 20 ns;
	instruction<=X"8D7CFF06"; --lw			
	wait for 20 ns;
	instruction<=X"349DD74F";	
	wait for 20 ns;
	instruction<=X"33A993EB";		
	wait for 20 ns;
	instruction<=X"309A9A52";		
	wait for 20 ns;
	instruction<=X"3601FDBB";		
	wait for 20 ns;
	instruction<=X"1231FF94"; --beq
	wait for 20 ns;
	instruction<=X"3C1B0001"; --lui
	wait;

end process data_gen;



end behavioral;
