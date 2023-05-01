library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.test_db_pkg.all;
use ieee.numeric_std.all;


entity test_flow is
	generic (
		counter_size 	: INTEGER := 19;
		TEST_4_6_7 		: std_logic_vector(2 downto 0) := "001";
		TEST_4_6_9 		: std_logic_vector(2 downto 0) := "010";
		TEST_FINISH		: std_logic_vector(11 downto 0) := x"aaa"
	);
	port(
		test_addr			: in std_logic_vector(2 downto 0) := "111";
		clk					: in std_logic;
		enable_test			: in std_logic;
		test_result			: out std_logic_vector(2 downto 0) := (others => '0');
		current_state_num	: out std_logic_vector(2 downto 0) := (others => '0');
		counter_out_p		: out std_logic_vector(counter_size downto 0) := (others => '0');
		test_id_num			: out std_logic_vector(7 downto 0) 	:= (others => '0');
		test_val_num		: out std_logic_vector(11 downto 0) := (others => '0');
		test_cnt_num		: out std_logic_vector(7 downto 0) 	:= (others => '0');
		result_vec_4_6_7	: out std_logic_vector(15 downto 0) := (others => '0');
		result_vec_4_6_9	: out std_logic_vector(15 downto 0) := (others => '0')
		);
end entity;


architecture arch of test_flow is

	type state_machine is (initial_state, idle_state, wait_for_done, test_done, failure, terminate_state);
	signal current_state 	: state_machine := initial_state;

	signal current_state_id						: std_logic_vector(2 downto 0);
	signal counter_out 							: std_logic_vector(counter_size downto 0) := (others => '0');
	signal test_val								: std_logic_vector(11 downto 0) := (others => '0');
	signal test_id								: std_logic_vector(7 downto 0) := (others => '0');
	signal test_cnt								: std_logic_vector(7 downto 0) := (others => '0');
	signal start_val							: std_logic := '0';
	signal enable_test_sig						: std_logic := '0';
	signal prev_enable_test						: std_logic := '0';

	------------------- rd wr ---------------------
	signal UUT_WR								: std_logic;
	signal UUT_RD					 			: std_logic; 
	signal sigUUT_DB0To7 						: std_logic_vector(7 downto 0);
	signal UUT_A0To2 							: std_logic_vector(2 downto 0);
	signal A0To2_IN								: std_logic_vector(2 downto 0);
	signal data_rd								: std_logic_vector(7 downto 0);
	signal data_wr 								: std_logic_vector(7 downto 0) := (others => '0');
	signal nWR_RD								: std_logic := '0';
	signal start								: std_logic := '0';
	signal done									: std_logic;

	-- uut mockup
	signal uut_rd_mock, uut_wr_mock	 			: std_logic;
	signal uut_sm								: std_logic_vector(1 downto 0);
	signal rd_cnt								: std_logic_vector(7 downto 0);

	component rd_wr_bdir_test is
		port(
			nWR_RD, start						: in std_logic;
			UUT_DB0To7							: inout std_logic_vector(7 downto 0); -- UUT input/output DB pins
			A0To2_IN							: in std_logic_vector(2 downto 0); -- func input A pins
			clk									: in std_logic; -- system clock
			data_wr								: in std_logic_vector(7 downto 0); -- func input data
			done								: out std_logic;
			UUT_RD, UUT_WR					 	: out std_logic; -- UUT input RD/WR pins
			UUT_A0To2							: out std_logic_vector(2 downto 0); -- UUT in A pins
			data_rd								: out std_logic_vector(7 downto 0);
			current_state_id					: out std_logic_vector(2 downto 0)
			);
	end component;

	component UUT_mock is
		port(
			data						: inout std_logic_vector(7 downto 0);
			addr						: in std_logic_vector(2 downto 0);
			uut_rd_mock					: in std_logic;
			uut_wr_mock					: in std_logic;
			clk							: in std_logic;
			uut_sm						: out std_logic_vector(1 downto 0);
			test_addr					: in std_logic_vector(2 downto 0);
			rd_cnt						: out std_logic_vector(7 downto 0) := (others => '0')
		);
	end component;
	
begin

	uut_rd_mock <= UUT_RD;
	uut_wr_mock <= UUT_WR;

	Rd_Wr : rd_wr_bdir_test 
		port map(
			UUT_DB0To7		=> sigUUT_DB0To7,
			A0To2_IN 		=> A0To2_IN,
			clk  			=> clk,
			UUT_A0To2 		=> UUT_A0To2,
			data_wr 		=> data_wr,
			data_rd			=> data_rd,
			UUT_RD 			=> UUT_RD,
			UUT_WR 			=> UUT_WR,
			start			=> start,
			done			=> done,
			nWR_RD			=> nWR_RD,
			current_state_id	=> current_state_id
		);

	UUT : UUT_mock
		port map(
			data 		=> sigUUT_DB0To7,
			clk			=> clk,
			uut_rd_mock	=> uut_rd_mock,
			uut_wr_mock	=> uut_wr_mock,
			addr		=> UUT_A0To2,
			uut_sm   	=> uut_sm,
			test_addr 	=> test_addr,
			rd_cnt		=> rd_cnt
		);

	process (clk, test_id, current_state) is -- RD/WR tests
		variable counter 	: integer range 0 to counter_size := 0;
		variable c			: integer := 0;
	begin
			if rising_edge(clk) then	
				case current_state is 
					when initial_state =>
						current_state_num <= "000";

						if enable_test = '1' and prev_enable_test = '0' then -- New test
							enable_test_sig <= '1';
							c := 0;
							test_id <= "00000000";
							result_vec_4_6_7 <= (others => '0');
							result_vec_4_6_9 <= (others => '0');
							start_val <= '0';
							prev_enable_test <= enable_test;
						end if;
									
						if enable_test_sig = '1' then
							if test_addr = TEST_4_6_7 then -- run test 4.6.7
								test_cnt <= test_cnt + '1';
								test_cnt_num <= test_cnt;
								
								test_val <= id2test_value_4_6_7(test_id);

								test_val_num <= test_val;
								
								if test_val = x"FFF" then
									-- pin 47 = not pin 47
									current_state <= wait_for_done;
								end if;
								
								if test_val = TEST_FINISH then -- End test after last subtest
									test_id <= "00000000";
									current_state <= terminate_state;
								else
									current_state <= idle_state;
									start_val <= not start_val;
							end if;
							end if;
							
							if test_addr = TEST_4_6_9 then -- run test 4.6.9
								test_val <= id2test_value_4_6_9(test_id);

								if test_val = x"FFF" then
									-- pin 47 = not pin 47
									current_state <= wait_for_done;
								end if;
								
								if test_val = TEST_FINISH then
									test_id <= "00000000";
									current_state <= terminate_state;
								else
									current_state <= idle_state;
									start_val <= not start_val;
								end if;
							end if;
						end if;
						
					when idle_state => 
						current_state_num <= "001";
						prev_enable_test <= enable_test;
						
						nWR_RD <= test_val(11);
						A0To2_IN <= test_val(10 downto 8);
						data_wr <= test_val(7 downto 0);
						
						counter := 0;
			
						start <= start_val;
						
						current_state <= wait_for_done;
						
					when wait_for_done => -- Wait for subsection result
						current_state_num <= "010";

						if done = '1' or test_val = x"FFF" then
							counter := 0; 
							current_state <= test_done;
						else
							if counter = 10 then
								test_result <= "001";
								current_state <= failure;
							else
								counter_out <= counter_out + 1;
								counter := counter + 1;
								counter_out_p <= counter_out;
							end if;
						end if;
						
					when test_done =>
						current_state_num <= "011";
						if test_addr = TEST_4_6_7 then -- Insert subsection to result vector (for test 4.6.7)
							if test_id > "00010000" then
								test_id <= "00000000";
								current_state <= terminate_state;
							else
								test_id_num <= test_id;
								test_id <= test_id + '1';
								
								if c < 16 then 
									if (test_val(11) = '1' and data_rd = test_val(7 downto 0)) or test_val(11) = '0' then 
										test_result <= "111";
										result_vec_4_6_7(c) <= '1';
									else
										test_result <= "000";
										result_vec_4_6_7(c) <= '0';
									end if;
									c := c + 1;
								end if;
								current_state <= initial_state;
							end if;
						elsif test_addr = TEST_4_6_9 then -- Insert subsection to result vector (for test 4.6.9)
							if test_id > "00010001" then
								current_state <= terminate_state;
							else 
								test_id <= test_id + '1';

								if (test_val(11) = '1' and data_rd = test_val(7 downto 0)) or test_val(11) = '0' or test_val = x"FFF" then 
									test_result <= "111";
									result_vec_4_6_9(c) <= '1';
								else
									test_result <= "000";
									result_vec_4_6_9(c) <= '0';
								end if;
								c := c + 1;
								current_state <= initial_state;
							end if;
						end if;
						
						
					when failure => -- faliure because of timeout 
						current_state_num <= "100";
						current_state <= initial_state;
										
					when terminate_state => -- Terminate test to prevent overlap 
						test_id <= "00000000";
						current_state_num <= "111";
						enable_test_sig <= '0';
						prev_enable_test <= '0';
						current_state <= initial_state;
					when others => null;
				end case;
		end if;
	end process;


end architecture;
