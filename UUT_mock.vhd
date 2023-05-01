library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity UUT_mock is
	port(
		data						: inout std_logic_vector(7 downto 0);
		uut_rd_mock, uut_wr_mock	: in std_logic;
		addr						: in std_logic_vector(2 downto 0);
		clk							: in std_logic;
		uut_sm						: out std_logic_vector(1 downto 0) := (others => '0');
		test_addr					: in std_logic_vector(2 downto 0);
		rd_cnt						: out std_logic_vector(7 downto 0) := (others => '0')
	);
end entity;


architecture arch of UUT_mock is

	type state_machine is (idle_state, wr_state, rd_state);
	signal current_state 	: state_machine := idle_state;
	signal inp 				: std_logic_vector(7 downto 0) := (others => '0');


	component tri_state_buffer
      port (
         clk: in std_logic;
         oe: in std_logic;
         bidir: inout std_logic_vector(7 downto 0);
         inp: in std_logic_vector(7 downto 0)
      );
   end component;

begin

	UUT : tri_state_buffer
      port map (
         clk => clk,
         bidir => data,
         inp => inp,
			oe => uut_rd_mock
      );

process (clk) is -- rd/wr specific test
	variable index 	: integer := 0;
	begin
			
	if rising_edge(clk) then
		case current_state is
			when idle_state =>
				uut_sm <= "00";
				if uut_rd_mock = '0' then
					current_state <= rd_state;
				else
					current_state <= wr_state;
				end if;
			when rd_state =>
				if test_addr = "001" then
					if uut_rd_mock = '0' then
						uut_sm <= "01";
						
						case index is
							when 0 => 
								inp <= "00000001";
							when 1 =>
								inp <= "00000010";
							when 2 =>
								inp <= "00000100";
							when 3 =>
								inp <= "00001000";
							when 4 =>
								inp <= "00010000";
							when 5 =>
								inp <= "00100000";
							when 6 =>
								inp <= "01000000";
							when 7 =>
								inp <= "10000000";
								-- index := 0;
							when 8 =>
								inp <= "00000010"; -- C1
								-- index := 0;
							when others => 
								inp <= "00000000";
								index := 0;
						end case;
						rd_cnt <= std_logic_vector(to_unsigned(index, 8));
						index := index + 1;
						current_state <= idle_state;
					else
						current_state <= wr_state;
					end if;
				elsif test_addr = "010" then
					if uut_rd_mock = '0' then
						uut_sm <= "01";

						case index is
							when 0 => 
								inp <= "00000000";
							when 1 =>
								inp <= "00000000";
							when 2 =>
								inp <= "11110000";
							when 3 =>
								inp <= "00000000";
							when 4 =>
								inp <= "00000000";
							when 5 =>
								inp <= "11110000";
							when 6 =>
								inp <= "11111111";
							when 7 =>
								inp <= "11111111";
								index := 0;
							when others => 
								inp <= "00000000";
						end case;

						index := index + 1;
						current_state <= idle_state;
					else
						current_state <= wr_state;
					end if;
				end if;
			
			when wr_state =>
				if uut_rd_mock = '0' then
					current_state <= rd_state;
				else
					uut_sm <= "10";
					inp <= "ZZZZZZZZ";
					current_state <= idle_state;
				end if;
		end case;
		
	end if;
end process;

end arch;
