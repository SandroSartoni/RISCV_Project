library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
	port(
	A, B:in signed(31 downto 0);
	OP:in std_logic_vector(3 downto 0);
	C:out signed(31 downto 0);
	Zero: out std_logic
);
end alu;	

Architecture behavioral of alu is
signal ADD_s,ADDI_s,XOR_s,SLT_s,ANDI_s,
		ORI_s,BEQ_s,LUI_s,LW_s,SW_s, SUB_s,ABS_s: signed(31 downto 0);--mancava segnale ABS_s
signal SRA_s: std_logic_vector(31 downto 0);
signal zero_s, C_s: signed(31 downto 0);
signal shamt_s: std_logic_vector(4 downto 0);

component adder is
	GENERIC(N: integer:=32);
	PORT(	A,B: in  signed(N-1 downto 0);
			OP : in  std_logic;
			S  : out signed(N-1 downto 0)
		);
end component;

component barrel is
	port(
	     input : in std_logic_vector (31 downto 0);
	     shift : in std_logic_vector (4 downto 0);
	     output : out std_logic_vector(31 downto 0)
	);
end component;

component abs_unit is
	GENERIC(N: integer:=32);
	PORT(	A: in  signed(N-1 downto 0);
		ABS_value  : out signed(N-1 downto 0)
		);
end component;

begin
shamt_s<=std_logic_vector(A(10 downto 6));

ADD_c: adder PORT MAP (A,B,'0', ADD_s);
XOR_s <= A XOR B;
SRA_c: barrel PORT MAP (std_logic_vector(B), shamt_s, SRA_s);
SUB_c: adder PORT MAP (A,B,'1', SUB_s);
SLT_s (31 downto 1)<= (OTHERS => '0');
SLT_s (0)<= (SUB_s(31));
ADDI_s<= ADD_s;
ANDI_s<= A AND (X"0000" & B(15 downto 0));
ORI_s <= A OR  (X"0000" & B(15 downto 0));
BEQ_s <= XOR_s;
LUI_S <= B(15 downto 0) & X"0000";
LW_s<=ADD_s;
SW_s<=ADD_s;
ABS_c: abs_unit port map (A, ABS_s);

C_s<=	ADD_s when OP=X"1" else 
	XOR_s when OP=X"2" else 
	signed(SRA_s)  when OP=X"3" else 
	SLT_s when OP=X"4" else 
	ADDI_s when OP=X"5" else 
	ANDI_s when OP=X"6" else 
	ORI_s when OP=X"7" else 
	BEQ_s when OP=X"8" else 
	LUI_s when OP=X"9" else 
	LW_s when OP=X"A" else 
	SW_s when OP=X"B" else 
	ABS_s when OP=X"C" else
	X"00000000";

C<=C_s;

zero<='1' when C_s= X"00000000" else '0';

end behavioral;
