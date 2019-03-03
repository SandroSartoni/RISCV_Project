library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Barrel is
	port(
	     input : in std_logic_vector (31 downto 0);
	     shift : in std_logic_vector (4 downto 0);
	     output : out std_logic_vector(31 downto 0)
	);
end Barrel;

architecture Behavioral of Barrel is

component MUX2 is 
	port(
	     A,B,SEL : in std_logic;
	     output : out std_logic
	);
end component;

signal l1,l2,l4,l8,l16: std_logic_vector (31 downto 0);

constant j:integer:=32; 

begin
--level1
mux131: MUX2 port map(input(31),input(31),shift(0),l1(31));
level1: for i in 0 to j-2 generate
mux_1:MUX2 port map(input(i),input(i+1),shift(0),l1(i));
end generate level1;

--level2
mux231: MUX2 port map(a=>l1(31),b=>input(31),SEL=>shift(1),output=>l2(31));
mux230: MUX2 port map(input(30),input(31),shift(1),l2(30));
level2: for i in 0 to j-3 generate
mux_2:MUX2 port map(l1(i),l1(i+2),shift(1),l2(i));
end generate level2;

--level4
mux431: MUX2 port map(l2(31),input(31),shift(2),l4(31));
mux430: MUX2 port map(l2(30),input(31),shift(2),l4(30));
mux429: MUX2 port map(l2(29),input(31),shift(2),l4(29));
mux428: MUX2 port map(l2(28),input(31),shift(2),l4(28));
level4: for i in 0 to j-5 generate
mux_4:MUX2 port map(l2(i),l2(i+4),shift(2),l4(i));
end generate level4;

--level8

level8MSB: for i in j-8 to j-1 generate
mux_8MSB:MUX2 port map(l4(i),input(31),shift(3),l8(i));
end generate level8MSB;

level8: for i in 0 to j-9 generate
mux_8:MUX2 port map(l4(i),l4(i+8),shift(3),l8(i));
end generate level8;

--level16

level16MSB: for i in j-16 to j-1 generate
mux_16MSB:MUX2 port map(l8(i),input(31),shift(4),l16(i));
end generate level16MSB;

level16: for i in 0 to j-17 generate
mux_16:MUX2 port map(l8(i),l8(i+16),shift(4),l16(i));
end generate level16;

output<=l16;

end Behavioral;

