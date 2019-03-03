library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

entity piso is
Port (jumbr,clk,Reset: in std_logic;
      pc_en : out std_logic);
end piso;

architecture Behavioral of piso is
signal Muxout, Muxout1,Muxout2,Jumbr1,Jumbr2, Jumbr3,Jumbrotto,sel,nclk, PC_en_s: std_logic;

component FF is
	port(
	D: in std_logic;
	CK: in std_logic;
	RST: in std_logic;
	Q:out std_logic
);
end component;

component MUX2 is
	port(
	     A,B,SEL : in std_logic;
	     output : out std_logic
	);
end  component;
signal not_sel,rst:std_logic;
begin
nclk<=not clk;
process (nclk, jumbr)
begin
--if nclk'event and nclk='1' then
	if (jumbr'event and jumbr='1') then
		muxout<='1';
	else
		muxout<='0';
	end if;
--end if;
end process;
shift1: FF port map(muxout,clk,Reset,Jumbr1);
Mux01: Mux2 port map(Jumbr1,muxout,muxout,Muxout1);

shift2: FF port map(Muxout1,clk,Reset,Jumbr2); 
--Mux02: Mux2 port map(Jumbr2,muxout,muxout,Muxout2);

--shift3: FF port map(Muxout2,clk,Reset,Jumbr3);

Mux03: Mux2 port map(Jumbr2,muxout,muxout,Jumbrotto);

PC_en_s<= not(Jumbrotto);
PC_en<=PC_en_s;
end Behavioral;
