-----------------------------------------------------------------------------------------------------------------------	 

-- UART Transmitter.
-- Miguel Gerardo Narváez González.
-- V1.0.
-- 11/09/21.	 

-- This file contains the UART transmitter.  This transmitter is able to transmit up to 8 bits of serial data, 1 start bit, 0, 1 or 2 stop bits,
-- and optional 0 or 1 even parity bit.  When a data package is send, SNDREADY is set to high for 1 clock cicle. UART configuration can be set in 
-- GENERIC section of the entity.	
-- The components used in this file must be included in the project's folder.  

-----------------------------------------------------------------------------------------------------------------------


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;

ENTITY UARTSimplex IS
	GENERIC(
	BAUDS: integer:=115200;  		--BAUDS
	FCLK: integer:=12000000;	
	DATAWIDTH: integer:=8; 	  --8 OR 7.
	STARTBIT: integer:=1;	
	STOPBIT: integer:=1;	 --1 OR 2.
	PARITYBIT: integer:=1 	 --EVEN PARITY 1 OR 0. PARITY ONLY WITH STOPBIT=1 OR STOPBIT=2.
	);
	PORT(
	SND: IN std_logic_vector (DATAWIDTH-1 DOWNTO 0);
	RST: IN std_logic;
	CLK: IN std_logic;
	TX: OUT std_logic;
	SNDREADY: OUT std_logic
	);
END ENTITY UARTSimplex;

ARCHITECTURE Structural OF UARTSimplex IS

COMPONENT Timer IS
	GENERIC(
	TICKS: integer:=10;
	BUSWIDTH: integer:=4
	);
	PORT(
	RST: IN std_logic;
	CLK: IN std_logic;
	SYN: OUT std_logic
	);	
 END COMPONENT;

COMPONENT DelayFlipFlops IS
	GENERIC(
	DELAY: integer:= 332;	--DELAY [ns] múltiplo de TCLK.
	TCLK: integer:= 83	 --Periodo del reloj [ns].
	);
	PORT (
	D: IN std_logic;
	RST: IN std_logic;
	CLK: IN std_logic;
    Q: OUT std_logic;
	Qn: OUT std_logic
	);	
END COMPONENT;

COMPONENT LatchSR IS
	PORT (
	SET: IN std_logic;
	CLR: IN std_logic;
	RST: IN std_logic;
	CLK: IN std_logic;
    SOUT: OUT std_logic );	
END COMPONENT;	 

COMPONENT ShiftRegister IS
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
END COMPONENT;		

COMPONENT EvenParityGenerator IS
	GENERIC(
	BUSWIDTH: integer:=8
	);
	PORT(
	DATA: IN std_logic_vector(BUSWIDTH-1 DOWNTO 0);
	PARITY: OUT std_logic
	);
END COMPONENT;

CONSTANT PackageWidth: integer:=(DATAWIDTH + STOPBIT + STARTBIT + PARITYBIT);
SIGNAL BYTESignal, BYTESignalDelayed, BITSignal, BYTESND, PARITYValue, PARITY: std_logic:='0';
SIGNAL DATASND: std_logic_vector(PackageWidth-1 DOWNTO 0):=(OTHERS=>'0');
SIGNAL SNDs: std_logic_vector(PackageWidth-1 DOWNTO 0):=(OTHERS=>'0');
SIGNAL DOUTs: std_logic_vector(PackageWidth-1 DOWNTO 0):=(OTHERS=>'0');

BEGIN
	
	
	SNDREADY<=BYTESignal;  
	
	--Data to be send is concatenated with START, SND, PARITY and STOP bits.
	SNDs<=  SND & '0' WHEN (STOPBIT=0 AND PARITYBIT=0) ELSE
		'1' & SND & '0' WHEN (STOPBIT=1 AND PARITYBIT=0) ELSE
		"11" & SND & '0' WHEN (STOPBIT=2 AND PARITYBIT=0) ELSE
		'1' & PARITY  & SND & '0' WHEN (STOPBIT=1 AND PARITYBIT=1) ELSE
		"11" & PARITY & SND & '0';			
	
	--Tx signal value is set to '0' or 'Z' (high impedance), depending on DOUTs (0) and considering that it is pulled up.
	TX<='0' WHEN DOUTs(0)='0' ELSE
		'Z';
 	

	--U1 generates a signal every time a data package is sent. This signal may vary depending on the number of bits. Buswidth is adjusted to the required width to accomplish TICKS number of counts.
	U1: Timer GENERIC MAP(TICKS=>((FCLK*PackageWidth)/BAUDS), BUSWIDTH=>integer(log2(real((FCLK*PackageWidth)/BAUDS)))+1) PORT MAP(RST=>RST, CLK=>CLK, SYN=>BYTESignal);	--TICKS=(FCLK [Hz] * Number of bits)/BAUDS
	
	--U2 generates a signal every time a bit is sent. This timer only starts to count when BYTESND='1'.  Buswidth is adjusted to the required width to accomplish TICKS number of counts.
	U2: Timer GENERIC MAP(TICKS=>(FCLK/BAUDS), BUSWIDTH=>integer(log2(real(FCLK/BAUDS)))+1) PORT MAP(RST=>BYTESND, CLK=>CLK, SYN=>BITSignal); 											--TICKS=FCLK [Hz] /BAUDS
	
	--U3 delays BYTESignal 3 clock cicles. This delay may range from 2 clock cicles to n clock cicles. 
	U3: DelayFlipFlops GENERIC MAP(DELAY=>249, TCLK=>83) PORT MAP(D=>BYTESignal, RST=>RST, CLK=>CLK, Q=>BYTESignalDelayed, Qn=>OPEN);	  	--DELAY must be multiple of TCLK [ns].
	  
	--BYTESignalDelayed sets the latch after it is cleared with BYTESignal. This produces a change from '0' to '1' in BYTESND.
	U4: LatchSR PORT MAP(SET=>BYTESignalDelayed, CLR=>BYTESignal, RST=>RST, CLK=>CLK, SOUT=>BYTESND);
	
	--When BYTESignalDelayed='1', U5 loads the value of the data package SNDs. DIR indicates the shifting direction(right). BITSignal, which is given by U2, must be '1' in order to shift SNDs 1 bit.
	U5: ShiftRegister GENERIC MAP(BUSWIDTH=>(DATAWIDTH + STOPBIT + STARTBIT + PARITYBIT)) PORT MAP(DIN=>SNDs, DIR=>'0', LOAD=>BYTESignalDelayed, SHIFT=>BITSignal, RST=>RST, CLK=>CLK, DOUT=>DOUTs); --BUSWIDTH=Number of bits.
	
	--U6 generates the parity bit based on data.
	U6: EvenParityGenerator	GENERIC MAP (BUSWIDTH=>DATAWIDTH) PORT MAP (DATA=>SND, PARITY=>PARITY);	   
	
	


END ARCHITECTURE Structural;
