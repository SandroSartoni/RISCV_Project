library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shift_right_arithmetic is
	port(
	     input : in std_logic_vector (31 downto 0);
	     shift : in std_logic_vector (4 downto 0);
	     output : out std_logic_vector(31 downto 0)
	);
end shift_right_arithmetic;

architecture Behavioral of shift_right_arithmetic is

signal shamt:integer RANGE 0 to 31; 
signal out_s: unsigned (31 downto 0);

begin
	output<=to_stdlogicvector(to_bitvector(input) sra to_integer(unsigned(shift)));	
end Behavioral;

