LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY Timer IS
	GENERIC(
	TICKS: integer:=10
	);
	PORT(
	RST: IN std_logic;
	CLK: IN std_logic;
	SYN: OUT std_logic
	);
	
END Timer;

ARCHITECTURE Behavioral OF Timer IS
SIGNAL Cp, Cn: integer:=0;
BEGIN		
	
	Combinational: PROCESS(Cp)
	BEGIN				   
		IF Cp = TICKS THEN
			Cn<= 0;
			SYN<='1';
		ELSE
			Cn<= Cp + 1;
			SYN<='0';	  
		END IF;
	END PROCESS Combinational;
	
	
	Sequential: PROCESS(RST,CLK)
	BEGIN		
		IF RST='0' THEN
			Cp<=0;
		ELSIF CLK'event AND CLK='1' THEN
			Cp<=Cn;
		END IF;	
	END PROCESS Sequential;
	
end	Behavioral;