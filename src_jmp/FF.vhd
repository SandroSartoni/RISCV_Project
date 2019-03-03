library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FF is --registro 12bit
	port(
	D: in std_logic;
	clk: in std_logic;
	RST: in std_logic;
	Q:out std_logic
);
end FF;	

Architecture progetto of FF is

begin

ff:process(clk,RST,D)	
	begin
	if RST='0'then
		Q<='0';
	elsif clk'event and clk='1' then
		Q<=D; 
	end if;
	end process;
end progetto;
	
