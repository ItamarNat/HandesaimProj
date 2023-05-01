library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;



package test_db_pkg is

	function id2test_value_4_6_7(value : std_logic_vector(7 downto 0)) return std_logic_vector;
	function to_string ( a: std_logic_vector) return string;
	function id2test_value_4_6_9(val	: std_logic_vector(7 downto 0)) return std_logic_vector;
	function getLine(s1 : in character; b1 : in std_logic; s2 : in character; b2 : in std_logic) return string;
	function getLine_4_6_9(s1 : in character; b1 : in std_logic; s2 : in character; b2 : in std_logic; s3 : in character; b3 : in std_logic) return string;
	function getLineAll(s1 : in string(1 to 5); b1 : in std_logic_vector(15 downto 0)) return string;
	
end test_db_pkg;



package body test_db_pkg is

	function id2test_value_4_6_7(value :in std_logic_vector(7 downto 0)) return std_logic_vector is -- 4.6.7
	begin
		case value(7 downto 0) is
			when X"00" => return x"001"; -- WR0 (01)
			when X"01" => return x"801"; -- RD0 (01)
			when X"02" => return x"002"; -- WR0 (02)
			when X"03" => return x"802"; -- RD0 (02)
			when X"04" => return x"004"; -- WR0 (04)
			when X"05" => return x"804"; -- RD0 (04)
			when X"06" => return x"008"; -- WR0 (08)
			when X"07" => return x"808"; -- RD0 (08)
			when X"08" => return x"010"; -- WR0 (10)
			when X"09" => return x"810"; -- RD0 (10)
			when X"0a" => return x"020"; -- WR0 (20)
			when X"0b" => return x"820"; -- RD0 (20)
			when X"0c" => return x"040"; -- WR0 (40)
			when X"0d" => return x"840"; -- RD0 (40)
			when X"0e" => return x"080"; -- WR0 (80)
			when X"0f" => return x"880"; -- RD0 (80)
			when X"10" => return x"aaa"; -- TEST DONE
			when others => return x"000"; -- can't happen
		end case;
	end;
	
	----------------------------------------------------------
	
	function id2test_value_4_6_9(val :in std_logic_vector(7 downto 0)) return std_logic_vector is -- 4.6.9
	begin
		case val(7 downto 0) is
			when X"00" => return x"FFF"; -- toggle pin 47 from '0' to '1'
			when X"01" => return x"900"; -- RD1 (00)
			when X"02" => return x"A00"; -- RD2 (00)
			when X"03" => return x"CF0"; -- RD4 (F0)
			when X"04" => return x"11F"; -- WR1 (1F)
			when X"05" => return x"2FC"; -- WR2 (FC)
			when X"06" => return x"3FF"; -- WR3 (FF)
			when X"07" => return x"900"; -- RD1 (00)
			when X"08" => return x"A00"; -- RD2 (00)
			when X"09" => return x"CF0"; -- RD4 (F0)
			when X"0a" => return x"FFF"; -- toggle pin 47 from '1' to '0'
			when X"0b" => return x"9FF"; -- RD1 (FF)
			when X"0c" => return x"AFF"; -- RD2 (FF)
			when X"0d" => return x"CFF"; -- RD4 (FF)
			when X"0e" => return x"1E0"; -- WR1 (E0)
			when X"0f" => return x"200"; -- WR2 (00)
			when X"10" => return x"300"; -- WR3 (00)
			when X"11" => return x"aaa"; -- TEST DONE
			when others => return x"000"; -- can't happen
		end case;
	end;
	
	----------------------------------------------------------

	function getLine(s1 : in character; b1 : in std_logic; s2 : in character; b2 : in std_logic) return string is
		variable line : string(1 to 80);
		variable b1_var : string(1 to 6);
		variable b2_var : string(1 to 6);
  	begin
		if b1 = '1' then
			b1_var := "PASSED";
		else
			b1_var := "FAILED";
		end if;
		
		if b2 = '1' then
			b2_var := "PASSED";
		else
			b2_var := "FAILED";
		end if;

		line := "       " & s1 & "." & " " & b1_var & "                      " & s2 & "." & " " & b2_var & "                                 ";
	return line;
	end;

	function getLine_4_6_9(s1 : in character; b1 : in std_logic; s2 : in character; b2 : in std_logic; s3 : in character; b3 : in std_logic) return string is
		variable line : string(1 to 80);
		variable s1_n, s3_n , s2_n: character := ' ';
		variable b1_var,  b2_var, b3_var : string(1 to 6);

  	begin
		

		if s1 = '0' then
			b1_var := "      ";
			s1_n := ' ';
		else
			if b1 = '1' then
				b1_var := "PASSED";
				s1_n := s1;
			else
				b1_var := "FAILED";
				s1_n := s1;
			end if;
		end if;

		if s3 = '0' then
			b3_var := "      ";
			s3_n := ' ';
		else
			if b3 = '1' then
				b3_var := "PASSED";
				s3_n := s3;
			else
				b3_var := "FAILED";
				s3_n := s3;
			end if;
		end if;
		
		if b2 = '1' then
			b2_var := "PASSED";
			s2_n := s2;
		else
			b2_var := "FAILED";
			s2_n := s2;
		end if;

		

		line := "       " & s1_n & "." & " " & b1_var & "                 " & s2_n & "." & " " & b2_var & "                " & s3_n & "." & " " & b3_var & "             ";
	return line;
	end;

	function to_string ( a: std_logic_vector) return string is
		variable b : string (1 to a'length) := (others => NUL);
		variable stri : integer := 1; 
	begin
		 for i in a'range loop
			  b(stri) := std_logic'image(a((i)))(2);
		 stri := stri+1;
		 end loop;
	return b;
	end function;

	function getLineAll(s1 : in string(1 to 5); b1 : in std_logic_vector(15 downto 0)) return string is
		variable line : string(1 to 80);
		variable b1_var : string(1 to 6);
  	begin
		if b1 = x"FFF" then
			b1_var := "PASSED";
		else
			b1_var := "FAILED";
		end if;
		
		line := "       " & s1 & " - " & b1_var & "                                                           ";
	return line;
	end;

end package body;	
