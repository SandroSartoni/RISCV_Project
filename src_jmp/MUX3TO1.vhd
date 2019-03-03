library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MUX3TO1 is
   generic(n: integer:=32);
	port(
	     A,B,C : in std_logic_vector(N-1 downto 0);
	     SEL : in std_logic_vector (1 downto 0);
	     output : out std_logic_vector(N-1 downto 0)
	);
end MUX3TO1;

architecture Behavioral of MUX3TO1 is
	begin
	output<= A when sel="00" else--messsi apici corretti""
		 B when sel="01" else
		 C;
end Behavioral;
