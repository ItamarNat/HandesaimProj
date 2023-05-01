library ieee;
use ieee.std_logic_1164.all;

entity rd_wr_bdir_test is
port(
	nWR_RD, start				: in std_logic; -- write enable
	UUT_DB0To7					: inout std_logic_vector(7 downto 0); -- UUT input/output DB pins
	A0To2_IN						: in std_logic_vector(2 downto 0); -- func input A pins
	clk							: in std_logic; -- system clock
	data_wr						: in std_logic_vector(7 downto 0) := (others => '0'); -- func input data
	done							: out std_logic; -- end process flag
	UUT_RD						: out std_logic := '1';
	UUT_WR						: out std_logic := '0'; -- UUT input RD/WR pins
	UUT_A0To2					: out std_logic_vector(2 downto 0) := (others => '0'); -- UUT in A pins
	data_rd						: out std_logic_vector(7 downto 0) := (others => '0');
	current_state_id			: out std_logic_vector(2 downto 0) := (others => '0')
	);
end entity;

architecture arch of rd_wr_bdir_test is

type state_machine is (initial_state, idle_state, WR_setup, RD_setup, WR_state, RD_state, WR_delay, RD_delay);
signal current_state 	: state_machine := initial_state;

signal data_sig 		: std_logic_vector(7 downto 0);
signal nWr_RD_sig		: std_logic;
signal prev_start 		: std_logic := '0';
signal data_out_enable	: std_logic := '1'; -- enable tri state

	component tri_state_buffer -- For bidirectional pins
      port (
         clk: in std_logic;
         oe: in std_logic;
         bidir: inout std_logic_vector(7 downto 0);
         inp: in std_logic_vector(7 downto 0)
      );
   end component;


begin

	tri_buffer : tri_state_buffer -- RdWr out to UUT (INOUT)
		port map(
			clk			=> clk,
			oe				=> data_out_enable,
			inp 			=> data_wr,
			bidir			=> UUT_DB0To7
		);
	

process (clk, current_state) is -- rd/wr specific test

	variable counter 	: integer range 0 to 1 := 0;
	begin
		
	if rising_edge(clk) then
		data_out_enable <= nWR_RD;
		case current_state is
			when initial_state => 
				current_state_id <= "000";
				current_state <= idle_state;
				
			when idle_state => -- setup address and data _WRITE_
				current_state_id <= "001";
--				UUT_RD <= '1';
--				UUT_WR <= '1';
				done <= '0';
				if (start = '1' and prev_start = '0') or (start = '0' and prev_start = '1') then -- any change to start pin
					if nWR_RD = '0' then -- mode WRITE
--						data_out_enable <= '0';
						current_state <= WR_setup;
					else
						current_state <= RD_setup;
--						data_out_enable <= '1';
					end if;
				end if;
				prev_start <= start;
				
			when WR_setup => -- change mode to Write
				current_state_id <= "010";
				UUT_A0To2 <= A0To2_IN; -- setup write address RD
				UUT_WR <= '0';
				UUT_RD <= '1';
				current_state <= WR_state;
				
			when RD_setup => -- Prepare UUT mode READ
				current_state_id <= "011";
				UUT_WR <= '1';
				UUT_RD <= '0';
				UUT_A0To2 <= A0To2_IN;
				
				current_state <= RD_delay;
				
			when RD_state => -- Read from INOUT pins
				current_state_id <= "100";
				data_rd <= UUT_DB0To7;
				done <= '1';
				UUT_WR <= '0';
				UUT_RD <= '1';
				current_state <= initial_state;	
			
			when WR_state => -- Wait one clk cycle and send data through INOUT pins
				current_state_id <= "101";
				
				current_state <= WR_delay;
				
			when WR_delay => -- delay by 2 clocks when WRITE state
			   current_state_id <= "110";
				if counter = 1 then
					counter := 0; 
					done <= '1';
					current_state <= initial_state;
				else
					counter := counter + 1;
				end if;
				
			when RD_delay => -- delay by 2 clocks when READ state
				current_state_id <= "111";
				if counter = 1 then
					counter := 0; 
					current_state <= RD_state;
				else
					counter := counter + 1;
				end if;
				
			when others => null;
		end case;
	end if;
end process;
end arch;