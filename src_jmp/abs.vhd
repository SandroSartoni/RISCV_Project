library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity abs_unit is
	GENERIC(N: integer:=32);
	PORT(	A: in  signed(N-1 downto 0);
		ABS_value  : out signed(N-1 downto 0)
		);
end abs_unit;

architecture behavioral of abs_unit is
begin
process(A)
begin--ho messo il begin
if (A(N-1)='1') then
	ABS_value <=-A;
else
	ABS_value <=A;
end if;
end process;

end architecture;
