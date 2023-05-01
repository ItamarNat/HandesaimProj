library ieee;
use ieee.std_logic_1164.all;
use work.test_db_pkg.all;

entity test_flow_testbench is
generic (
		counter_size : INTEGER := 19); 
end entity;

architecture arch of test_flow_testbench is

component rd_wr_bdir_test is
port(
	nWR_RD, start						: in std_logic; -- write enable
	UUT_DB0To7							: inout std_logic_vector(7 downto 0); -- UUT input/output DB pins
	A0To2_IN								: in std_logic_vector(2 downto 0); -- func input A pins
	clk									: in std_logic; -- system clock
	data_wr								: in std_logic_vector(7 downto 0); -- func input data
	done									: out std_logic;
	UUT_RD, UUT_WR					 	: out std_logic; -- UUT input RD/WR pins
	UUT_A0To2							: out std_logic_vector(2 downto 0); -- UUT in A pins
	data_rd								: out std_logic_vector(7 downto 0);
	current_state_id					: out std_logic_vector(2 downto 0)
	);
end component;

component test_flow
	
	port(
		test_addr				: in std_logic_vector(2 downto 0);
		clk						: in std_logic;
		data_rd					: in std_logic_vector(7 downto 0);
		done						: in std_logic;
		test_result				: out std_logic_vector(2 downto 0);
		current_state_num		: out std_logic_vector(2 downto 0);
		counter_out_p			: out std_logic_vector(counter_size downto 0);
		nWR_RD, start			: out std_logic;
		A0To2_IN					: out std_logic_vector(2 downto 0);
		data_wr					: out std_logic_vector(7 downto 0);
		counter_test_temp		: out std_logic_vector(7 downto 0);
		test_id_num				: out std_logic_vector(11 downto 0)
	);	
end component;

component UUT_mock is
	port(
		data							: inout std_logic_vector(7 downto 0);
		addr							: in std_logic_vector(2 downto 0);
		uut_rd_mock					: in std_logic;
		uut_wr_mock					: in std_logic;
		clk							: in std_logic;
		uut_sm						: out std_logic_vector(1 downto 0)
	);
end component;

-- rd wr
signal sigUUT_DB0To7 						: std_logic_vector(7 downto 0);
signal nWR_RD									: std_logic := '0';			
signal start									: std_logic := '0'; 
signal done										: std_logic;
signal UUT_WR									: std_logic;
signal UUT_RD					 				: std_logic; 
signal A0To2_IN 								: std_logic_vector(2 downto 0) := (others => '0');
signal data_wr 								: std_logic_vector(7 downto 0) := (others => '0');
signal data_rd 								: std_logic_vector(7 downto 0);
signal UUT_A0To2 								: std_logic_vector(2 downto 0);
signal current_state_id						: std_logic_vector(2 downto 0);

-- test flow
signal clk						: std_logic := '0';
signal test_id					: std_logic_vector(11 downto 0) := (others => '0');
signal test_result			: std_logic_vector(2 downto 0);
signal current_state_num	: std_logic_vector(2 downto 0);
signal counter_out_p			: std_logic_vector(counter_size downto 0);
signal test_addr				: std_logic_vector(2 downto 0);
signal counter_test_temp	: std_logic_vector(7 downto 0);



-- uut mockup
signal uut_rd_mock, uut_wr_mock	 		: std_logic;
signal uut_sm									: std_logic_vector(1 downto 0);

begin

Rd_Wr : rd_wr_bdir_test 
	port map(
		UUT_DB0To7		=> sigUUT_DB0To7,
		A0To2_IN 		=> A0To2_IN,
		clk  				=> clk,
		UUT_A0To2 		=> UUT_A0To2,
		data_wr 			=> data_wr,
		data_rd			=> data_rd,
		UUT_RD 			=> UUT_RD,
		UUT_WR 			=> UUT_WR,
		done				=> done,
		start				=> start,
		nWR_RD			=> nWR_RD,
		current_state_id	=> current_state_id
	);

test : test_flow
port map (
	test_addr				=> test_addr,
	clk 						=> clk,
	done						=> done,
	test_result				=> test_result,
	current_state_num 	=> current_state_num,
	counter_out_p 			=> counter_out_p,
	nWR_RD 					=> nWR_RD,
	start 					=> start,
	A0To2_IN					=> A0To2_IN,	
	data_wr 					=> data_wr,
	data_rd					=> data_rd,
	counter_test_temp => counter_test_temp,
	test_id_num				=> test_id
);

UUT : UUT_mock
	port map(
		data 		=> sigUUT_DB0To7,
		clk		=> clk,
		uut_rd_mock	=> uut_rd_mock,
		uut_wr_mock	=> uut_wr_mock,
		addr		=> UUT_A0To2,
		uut_sm   => uut_sm
	);


clk <= not clk after 10 ns;
uut_rd_mock <= UUT_RD;
uut_wr_mock <= UUT_WR;


process
begin
  while true loop
    report "test_id = " & to_string(test_id);
    wait for 10 ns; -- wait for 10 nanoseconds before checking the signal again
  end loop;
end process;

process 
begin

-- run test 4.6.7
	test_addr <= "001";
	
	wait until test_id = x"aaa";
	
-- run test 4.6.9
	test_addr <= "010";
	
	wait until test_id = x"aaa";
	
--	wait;
end process;
end architecture;