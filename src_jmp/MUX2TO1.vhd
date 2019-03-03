library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MUX2TO1 is
   generic(n: integer:=32);
	port(
	     A,B : in std_logic_vector(N-1 downto 0);
	     SEL : in std_logic;
	     output : out std_logic_vector(N-1 downto 0)
	);
end MUX2TO1;

architecture Behavioral of MUX2TO1 is
	begin
	output<= a when sel='0' else b;
end Behavioral;
