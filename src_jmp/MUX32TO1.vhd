LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY MUX32TO1 IS
GENERIC ( N : INTEGER:=32);
	PORT (I0,I1,I2,I3,I4,I5,I6,I7,I8,I9,I10,I11,I12,I13,I14,I15,I16,I17,I18,I19,I20,I21,I22,I23,I24,I25,I26,I27,I28,I29,I30,I31: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		  S	    : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
		  O     : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END ENTITY MUX32TO1;

ARCHITECTURE STRUCTURE OF MUX32TO1 IS
BEGIN

O <=	I0  WHEN S="00000" ELSE
		I1  WHEN S="00001" ELSE
		I2  WHEN S="00010" ELSE
		I3  WHEN S="00011" ELSE
		I4  WHEN S="00100" ELSE
		I5  WHEN S="00101" ELSE
		I6  WHEN S="00110" ELSE
		I7  WHEN S="00111" ELSE
		I8  WHEN S="01000" ELSE
		I9  WHEN S="01001" ELSE
		I10 WHEN S="01010" ELSE
		I11 WHEN S="01011" ELSE
		I12 WHEN S="01100" ELSE
		I13 WHEN S="01101" ELSE
		I14 WHEN S="01110" ELSE
		I15 WHEN S="01111" ELSE
		I16 WHEN S="10000" ELSE
		I17 WHEN S="10001" ELSE
		I18 WHEN S="10010" ELSE
		I19 WHEN S="10011" ELSE
		I20 WHEN S="10100" ELSE
		I21 WHEN S="10101" ELSE
		I22 WHEN S="10110" ELSE
		I23 WHEN S="10111" ELSE
		I24 WHEN S="11000" ELSE
		I25 WHEN S="11001" ELSE
		I26 WHEN S="11010" ELSE
		I27 WHEN S="11011" ELSE
		I28 WHEN S="11100" ELSE
		I29 WHEN S="11101" ELSE
		I30 WHEN S="11110" ELSE
		I31;
		
END STRUCTURE;