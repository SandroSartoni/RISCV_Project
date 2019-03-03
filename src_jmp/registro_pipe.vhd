library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registro_pipe is --registro 12bit
	generic (N:integer:=15);
	port(
	D: in std_logic_vector(N-1 downto 0);
	clk: in std_logic;
	RST: in std_logic;
	Q: out std_logic_vector(N-1 downto 0)
);
end registro_pipe;	

Architecture progetto of registro_pipe is

begin

ff:process(clk,RST,D)	
	begin
	if RST='0'then
		Q<=(others=>'0');
	elsif clk'event and clk='1' then
			Q<=D;
	end if;
	end process;
end progetto;
	
