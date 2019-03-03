library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
	GENERIC(N: integer:=32);
	PORT(	A,B: in  signed(N-1 downto 0);
			OP : in  std_logic;
			S  : out signed(N-1 downto 0)
		);
end adder;

architecture behavioral of adder is
signal C,A_s, B_s: signed(N downto 0);
begin
A_s<=A(N-1)&A;
B_s<=B(N-1)&B;
--process(A,B,OP)
--    begin
--if op='0' then -
--	C<=A_s+B_s; 
--else 
--	C<=A_s-B_s; 
--end if;
--end process;

C<= A_s+B_s when OP='0' else
	A_s-B_s when OP='1';

--C<=A+B when OP='0' else A-B;
saturate: process(C)
begin
	if (C(N)/=C(N-1)) then
		if (C(N)='1') then
			S(N-1) <= '1';
			S(N-2 downto 0) <= (OTHERS =>'0');
		else
			S(N-1) <= '0';
			S(N-2 downto 0) <= (OTHERS =>'1');
		end if;
	else 
		S <= C(N-1 downto 0);
	end if;
end process saturate; 

end behavioral;
