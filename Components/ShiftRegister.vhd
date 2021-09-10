LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL; 
USE IEEE.NUMERIC_STD.ALL;


ENTITY ShiftRegister IS 
	GENERIC(
	BUSWIDTH: integer:=8
	);
	PORT(  
	DIN: IN std_logic_vector(BUSWIDTH-1 DOWNTO 0);
	DIR: IN std_logic; 
	LOAD: IN std_logic;
	SHIFT: IN std_logic; 
	RST: IN std_logic;
	CLK: IN std_logic;
	DOUT: OUT std_logic_vector(BUSWIDTH-1 DOWNTO 0)
	);
END ENTITY ShiftRegister;


ARCHITECTURE Behavorial OF ShiftRegister IS

SIGNAL Qp, Qn: std_logic_vector(BUSWIDTH-1 DOWNTO 0):=(OTHERS=>'0');	

BEGIN
	
	
	Combinational: PROCESS(SHIFT, DIR, LOAD, DIN, Qp)  
	BEGIN
		
		IF LOAD = '1' THEN
			Qn<=DIN;
		ELSIF SHIFT='1' THEN 
			
			IF DIR='1' THEN
				Qn<=std_logic_vector(SHIFT_LEFT(unsigned(Qp),1)); 
			ELSE
				Qn<=std_logic_vector(SHIFT_RIGHT(unsigned(Qp),1)); 
			END IF;
		
		ELSE
			Qn<=Qp;	
		END IF;
		
		
	END PROCESS Combinational;
	
	
	Sequential: PROCESS (CLK, RST) 
	BEGIN
		
		IF RST='0' THEN	 
			Qp<=(OTHERS=>'0');
			DOUT<=(OTHERS=>'0');
		ELSIF CLK'EVENT AND CLK='1' THEN  
			Qp<=Qn;
			DOUT<=Qp;
		END IF;
		
	END PROCESS Sequential;
	
	
END ARCHITECTURE Behavorial;