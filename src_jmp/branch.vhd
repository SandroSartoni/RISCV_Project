library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity brancher is
port(
PC4: in std_logic_vector(31 downto 0);
IMMEDIATE: in std_logic_vector(25 downto 0);
EXT_IMMEDIATE: in std_logic_vector(31 downto 0);
ZERO: in std_logic;
BRANCH: in std_logic;
jump: in std_logic;
JUMP_address: out std_logic_vector(31 downto 0)
);
end brancher;


architecture behavior of brancher is

component MUX2TO1 is
   generic(n: integer:=32);
	port(
	     A,B : in std_logic_vector(N-1 downto 0);
	     SEL : in std_logic;
	     output : out std_logic_vector(N-1 downto 0)
	);
end component;
signal BRANCH_add,PC_jmp,PC_branch: std_logic_vector(31 downto 0);
signal branch_sel: std_logic;--jump è un ingresso

begin
BRANCH_add<=std_logic_vector(signed(PC4)+ signed(EXT_IMMEDIATE(29 downto 0) &"00"));
branch_sel<= branch and zero;
BR_MUX: MUX2TO1 PORT MAP(PC4, BRANCH_add, branch_sel, PC_branch);
PC_jmp<=(PC4(31 downto 28) & IMMEDIATE(25 downto 0) & "00");
jmp_MUX: MUX2to1 port map (PC_branch,PC_jmp,jump,JUMP_address);

end behavior;--c'era scritto behavioral
