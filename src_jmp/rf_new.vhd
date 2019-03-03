library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity rf is
port(
	clk, resetn, regwrite: in std_logic;
	readregister1,readregister2: in std_logic_vector(4 downto 0);
	writeregister: in std_logic_vector(4 downto 0);
	writedata: in std_logic_vector(31 downto 0);
	readdata1: out std_logic_vector(31 downto 0); 
	readdata2: out std_logic_vector(31 downto 0)
);
end rf;

architecture Behavioral of rf is

--type and signal declaration for RAM.
type rf_type is array(0 to 31) of std_logic_vector(31 downto 0);--#row=2^bitaddress(??)
signal regoutput : rf_type;-- := (others => (others => '0'));

begin

process(clk, resetn)
begin
    if (resetn='0') then
	for i in 0 to 31 loop
	    regoutput(i)<=X"00000000";
	end loop;
    elsif(rising_edge(clk)) then
		readdata1 <= regoutput(to_integer(unsigned(readregister1)));
		readdata2 <= regoutput(to_integer(unsigned(readregister2)));
	end if;
end process;
process(regwrite)
begin
	if(regwrite = '1') then    
                	regoutput(to_integer(unsigned(writeregister))) <= writedata;
	end if;
end process;

            
end Behavioral;
