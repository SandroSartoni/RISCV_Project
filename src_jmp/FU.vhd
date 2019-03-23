library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FU is
	port(
	     RegR1,RegR2,RegW_1d,RegW_2d : in std_logic_vector(4 downto 0);
	     SelMuxOp1,SelMuxOp2 : out std_logic_vector(1 downto 0)
	);
end FU;

architecture Behavioral of FU is
	begin
	SelMuxOp1<=	"00" when RegR1="00000" else
				"10" when (RegR1=RegW_1d) else
				"01" when (RegR1=RegW_2d) else
				"00";
	
	SelMuxOp2<=	"00" when RegR2="00000" else
				"10" when (RegR2=RegW_1d) else
				"01" when (RegR2=RegW_2d) else
				"00";	
end Behavioral;