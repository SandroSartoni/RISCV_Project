library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pc is
    Port ( clk : in  std_logic;
           Resetn: in std_logic;
		   Enable: in std_logic;
           NextAddress : in  std_logic_vector (31 downto 0);
           CurrentAddress : out  std_logic_vector (31 downto 0) 
           );
end pc;

architecture Behavioral of pc is
begin

  process (clk,Resetn)
  begin
	if Resetn='0' then		
	 CurrentAddress<= X"00400000";--aggiunta tonde
	elsif clk'event and clk='1' then
		if (Enable='1') then
			CurrentAddress<=NextAddress;
	    	end if;
	end if;
  end process;
 
end Behavioral;
