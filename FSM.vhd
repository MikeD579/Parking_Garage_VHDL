----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:21:35 12/01/2019 
-- Design Name: 
-- Module Name:    Main - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FSM is
    Port ( 	carIN 		: in  STD_LOGIC;
           	carOUT 		: in  STD_LOGIC;
		fireLane	: in  STD_LOGIC;
		overrideSW	: in  STD_LOGIC;
		gateSW		: in  STD_LOGIC;
			  
		RST		: in  STD_LOGIC;
		CLK		: in  STD_LOGIC;
			  
		decoderOUT	: out STD_LOGIC_VECTOR (6 downto 0);
			  
		alarm		: out STD_LOGIC;
		capacityLED	: out STD_LOGIC;
		gate		: out STD_LOGIC);
end FSM;

architecture Behavioral of FSM is
	
	--This will be a slow clock with a period of about 1 second
	signal Clock 		: STD_LOGIC;
	signal Clock_alarm	: STD_LOGIC;
	signal CLK_DIV 		: STD_LOGIC_VECTOR (18 downto 0);
	
	--Enumerated type and signal declaration for a state machine
	type num_State is (zero, one, two, three, four, five, six, seven, eight, nine);
	signal State : num_State := nine;
	
	--count for when after a car goes through the sensor to make it wait one second
	signal gateCount	: integer range 0 to 32 := 0;
	signal fireCount	: integer range 0 to 16 := 0;
	signal countafter	: integer range 0 to 16 := 0;
	constant target 	: integer := 16;
	
	--count for if the car blocks the sensor for 10sec
	signal countWhile 	: integer range 0 to 160 := 0;
	constant soundAlarm 	: integer := 160;
	
	signal alarmON : STD_LOGIC;
	
	signal gateAUTO : STD_LOGIC;
	
	signal ready : STD_LOGIC;
	
	signal setup : boolean := false;
	
	signal LED : STD_LOGIC_VECTOR (3 downto 0);

begin

--Divides the standard clock frequency to make it slower
	Clock_DIV : process(CLK) is
	begin
		if(falling_edge(CLK)) then
			CLK_DIV <= CLK_DIV + '1';
		end if;
	end process;
			
	--Sets the divided clock to the signal Clock
	Clock <= CLK_DIV(18);
	Clock_alarm <= CLK_DIV(14);
	
	--testing alarm
	alarm <= Clock_alarm and alarmON;
	
	--decoder for 8 segment LED
	with LED select
		decoderOUT <= 	"0000001" when "0000",
							"1001111" when "0001",
							"0010010" when "0010",
							"0000110" when "0011",
							"1001100" when "0100",
							"0100100" when "0101",
							"1100000" when "0110",
							"0001111" when "0111",
							"0000000" when "1000",
							"0001100" when "1001",
							"1111111" when others;
	
--MAIN process is triggered when the divided clock changes
	Main : process(Clock) is
	begin
		if(falling_edge(Clock)) then	--if clock rises
			if(RST = '0') then			--if reset is low
				--Reset Values
				State <= nine;
				LED <= ("1001");
			else
		
				--when you turn on the CPLD it will set the inital state and LED value
				if (NOT(setup)) then
					State <= nine;
					LED <= "1001";
					setup <= true;
				end if;
			
				if (overrideSW = '0') then
					if (gateAUTO = '1') then
						if(gateCount = 32) then
							gateCount <= 0;
							gate <= '1';
						else
							gateCount <= gateCount + 1;
						end if;
					else
						gate <= '0';
					end if;
				else
					gate <= gateSW;
				end if;
				
				-- if the sensors are both unblocked
				if (carIN = '1' and carOUT = '1' and fireLane = '1') then
					ready <= '1';
					countWhile <= 0;
					alarmON <= '0';
				end if;
				
				--Fire Lane
				if (fireLane = '0' and fireCount = 16) then
					fireCount <= 0;
					alarmON <= '1';
				else
					fireCount <= fireCount + 1;
				end if;
				
				--if sensorOUT tripped count up
				if(carIN = '1' and carOUT = '0') then 
				
					--Turn on alarm if count reaches over 10 seconds
					if (countWhile = soundAlarm) then
						alarmON <= '1';
					else
						countWhile <= countWhile + 1;
					end if;
					
					--if the it is passed a second and the button has been released count up
					if(countafter = target and ready = '1') then -- if carOUT
						countafter <= 0;
						ready <= '0';
						
						--Default Values
						LED <= ("1001");
					
						case State is
						
							when zero =>
								LED <= ("0001");
								State <= one;
								gateAUTO <= '0';
								capacityLED <= '1';
								
							when one =>
								LED <= ("0010");
								State <= two;
								
							when two =>
								LED <= ("0011");
								State <= three;
								
							when three =>
								LED <= ("0100");
								State <= four;
								
							when four =>
								LED <= ("0101");
								State <= five;
								
							when five =>
								LED <= ("0110");
								State <= six;
								
							when six =>
								LED <= ("0111");
								State <= seven;
								
							when seven =>
								LED <= ("1000");
								State <= eight;
								
							when eight =>
								LED <= ("1001");
								State <= nine;
								
							when nine =>
								LED <= ("1001");
								State <= nine;
								
						end case;
					else
						countafter <= countafter + 1;
					end if; -- end if carOUT
				
				--if sensorIN tripped count down
				elsif(carIN = '0' and carOUT = '1') then
					
					--Turn on alarm if count reaches over 10 seconds
					if (countWhile = soundAlarm) then
						alarmON <= '1';
					else
						countWhile <= countWhile + 1;
					end if;
					
					--if the it is passed a second and the button has been released count down
					if(countafter = target and ready = '1') then -- if carIN
						countafter <= 0;
						ready <= '0';
							
						--Default Values
						LED <= ("1001");
					
						case State is
						
							when zero =>
								LED <= ("0000");
								State <= zero;
								
							when one =>
								LED <= ("0000");
								gateAUTO <= '1';
								capacityLED <= '0';
								State <= zero;
								
							when two =>
								LED <= ("0001");
								State <= one;
								
							when three =>
								LED <= ("0010");
								State <= two;
								
							when four =>
								LED <= ("0011");
								State <= three;
								
							when five =>
								LED <= ("0100");
								State <= four;
								
							when six =>
								LED <= ("0101");
								State <= five;
								
							when seven =>
								LED <= ("0110");
								State <= six;
								
							when eight =>
								LED <= ("0111");
								State <= seven;
								
							when nine =>
								LED <= ("1000");
								State <= eight;
								
						end case;
					else
						countafter <= countafter + 1;
					end if; -- end if carIN
				end if; -- end if sensos tripped
				
				if (countafter > 0 and countafter < target) then -- if countafter
				countafter <= countafter + 1;
				end if; -- end if countafter
				
			end if; -- end if reset
		end if; -- end if clock rises
		
	end process;
--End of MAIN process

end Behavioral;

