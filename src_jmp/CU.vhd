library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CU is
port(
	resetn: in std_logic;
	OPCODE: in std_logic_vector(5 downto 0);
	FUNCT : in std_logic_vector(5 downto 0);
	Jump,
	Branch,
	Regdst,
	RegWrite,
	AluSrc,
	MemWrite,
	Mux_sra,
	MemRead,
	Mem2Reg: out std_logic;
	ALU_op : out std_logic_vector(3 downto 0)
);
end CU;


architecture behavior of CU is

signal opcode_s,funct_s: std_logic_vector(7 downto 0);
--signal outarray: std_logic_vector(8 downto 0);
begin

opcode_s<="00" & OPCODE;
funct_s <= "00" & FUNCT;
process(opcode_s,resetn, funct_s)
begin

if(resetn='0') then
	Jump<='0';
	Branch<='0';
	Regdst<='0';
	RegWrite<='0';
	AluSrc<='0';
	MemWrite<='0';
	MemRead<='0';
	Mem2Reg<='0';
	ALU_op<=X"0";
	Mux_sra<='0';
else
	Jump<='0';
	Branch<='0';
	Regdst<='0';
	RegWrite<='0';
	AluSrc<='0';
	MemWrite<='0';
	MemRead<='0';
	Mem2Reg<='1';
	ALU_op<=X"0";
	Mux_sra<='0';
case opcode_s is
	when X"00"=> 	if 		(funct_s=X"00") then 
ALU_op <= X"0";
Regdst<='1'; 
AluSrc<='0';

RegWrite<='0'; --SLL for NOP
					elsif (funct_s=X"20") then 
ALU_op <= X"1";
Regdst<='1'; 
AluSrc<='0';

RegWrite<='1'; --ADD
					elsif (funct_s=X"26") then 
ALU_op <= X"2";
Regdst<='1'; 
AluSrc<='0';
RegWrite<='1'; --XOR
					elsif (funct_s=X"03") then 
ALU_op <= X"3";
Regdst<='1'; 
AluSrc<='0';
RegWrite<='1'; 
Mux_sra<='1';	--SRA
					elsif (funct_s=X"2a") then 
ALU_op <= X"4";
Regdst<='1'; 
AluSrc<='0';
RegWrite<='1'; --SLT
					elsif (funct_s=X"05") then 
ALU_op <= X"C";
Regdst<='1'; 
AluSrc<='0';
RegWrite<='1'; --ABS	
					end if;

	when X"08"=> ALU_op<=X"5";Regdst<='0'; AluSrc<='1';RegWrite<='1';--adDI--
	when X"0c"=> ALU_op<=X"6";Regdst<='0'; AluSrc<='1';RegWrite<='1';--andi--
	when X"0d"=> ALU_op<=X"7";Regdst<='0'; AluSrc<='1';RegWrite<='1';--ori--
	when X"04"=> ALU_op<=X"8";AluSrc<='0'; Branch<='1';Jump<='0';--BEQ--
	when X"02"=> Jump<='1'; --jump--
	when X"0f"=> ALU_op<=X"9";Regdst<='0'; Jump<='0';  AluSrc<='1'; RegWrite<='1';--lui--
	when X"23"=> ALU_op<=X"A";Regdst<='0'; MemRead<='1';Mem2Reg<='0';RegWrite<='1';AluSrc<='1';Branch<='0';Jump<='0';--lw--
	when X"2b"=> ALU_op<=X"B";Branch<='0';MemWrite<='1';AluSrc<='1';Branch<='0';Jump<='0';--sw--
	when others =>
end case;
	
end if;

end process;

end behavior;
