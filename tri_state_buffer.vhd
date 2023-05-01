LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tri_state_buffer IS
    PORT(
        bidir   : out STD_LOGIC_VECTOR (7 DOWNTO 0);
        oe, clk : IN STD_LOGIC;
        inp     : IN STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0')	
		  );
END tri_state_buffer;

ARCHITECTURE tri_buffer OF tri_state_buffer IS
BEGIN  
	bidir <= "ZZZZZZZZ" when oe = '1' else inp; 
                                      
END tri_buffer;
