library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MUX2 is
	port(
	     A,B,SEL : in std_logic;
	     output : out std_logic
	);
end MUX2;

architecture Behavioral of MUX2 is
	begin
	output<= a when sel='0' else b;
end Behavioral;
