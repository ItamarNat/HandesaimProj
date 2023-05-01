library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;



package ps2_pkg is

	type ascii2d is
		record
		  c 		: character;
		  ascii : STD_LOGIC_VECTOR(7 downto 0);
	   end record;

	function nibble2char(value : STD_LOGIC_VECTOR(3 downto 0)) return CHARACTER;
	function key2ascii(key_data : character) return std_logic_vector;
	function key_code2char(key_data : STD_LOGIC_VECTOR(7 downto 0)) return ascii2d;
	function debug (param_name 	: string (1 to 10);	
	 				value		: integer) return string;
end;



package body ps2_pkg is

	function nibble2char(value :in STD_LOGIC_VECTOR(3 downto 0)) return CHARACTER is
	begin
		case value(3 downto 0) is
			when X"0" => return '0';
			when X"1" => return '1';
			when X"2" => return '2';
			when X"3" => return '3';
			when X"4" => return '4';
			when X"5" => return '5';
			when X"6" => return '6';
			when X"7" => return '7';
			when X"8" => return '8';
			when X"9" => return '9';
			when X"a" => return 'A';
			when X"b" => return 'B';
			when X"c" => return 'C';
			when X"d" => return 'D';
			when X"e" => return 'E';
			when X"f" => return 'F';
			when others => return '0'; -- can't happen
		end case;
	end function nibble2char;

	---------------------------------------------------------------

	function key2ascii(key_data :in character) return std_logic_vector is
		variable temp : std_logic_vector(7 downto 0);
	begin
		case key_data is
			when '0' => temp := x"30"; -- 0
			when '1' => temp := x"31"; -- 1
			when '2' => temp := x"32"; -- 2
			when '3' => temp := x"33"; -- 3
			when '4' => temp := x"34"; -- 4
			when '5' => temp := x"35"; -- 5
			when '6' => temp := x"36"; -- 6
			when '7' => temp := x"37"; -- 7
			when '8' => temp := x"38"; -- 8
			when '9' => temp := x"39"; -- 9
					--    --
			when 'A' => temp := x"41"; -- A
			when 'B' => temp := x"42"; -- B
			when 'C' => temp := x"43"; -- C
			when 'D' => temp := x"44"; -- D
			when 'E' => temp := x"45"; -- E
			when 'F' => temp := x"46"; -- F
			when 'G' => temp := x"47"; -- G
			when 'H' => temp := x"48"; -- H
			when 'I' => temp := x"49"; -- I
			when 'J' => temp := x"4A"; -- J
			when 'K' => temp := x"4B"; -- K
			when 'L' => temp := x"4C"; -- L
			when 'M' => temp := x"4D"; -- M
			when 'N' => temp := x"4E"; -- N
			when 'O' => temp := x"4F"; -- O
			when 'P' => temp := x"50"; -- P
			when 'Q' => temp := x"51"; -- Q
			when 'R' => temp := x"52"; -- R
			when 'S' => temp := x"53"; -- S
			when 'T' => temp := x"54"; -- T
			when 'U' => temp := x"55"; -- U
			when 'V' => temp := x"56"; -- V
			when 'W' => temp := x"57"; -- W
			when 'X' => temp := x"58"; -- X
			when 'Y' => temp := x"59"; -- Y
			when 'Z' => temp := x"5A"; -- Z
					 
			when '`' => temp := x"60"; -- `
			when '-' => temp := x"2D"; -- -
			when '=' => temp := x"3D"; -- =
			when '[' => temp := x"5B"; -- [
			when ']' => temp := x"5D"; -- ]
			when '\' => temp := x"08"; -- \ -- test 5c
			when ';' => temp := x"3B"; -- ;
			when ''' => temp := x"27"; -- '
			when ',' => temp := x"2C"; -- ,
			when '.' => temp := x"2E"; -- .
			when '/' => temp := x"2F"; -- /
			when '_' => temp := x"5f"; -- _
			when '%' => temp := x"25"; -- %
			when '^' => temp := x"5E"; -- ^
					--   --
			when ' ' => temp := x"20";  -- (space)
			when '$' => temp := x"0D";  -- (enter, cr)

			when others => temp := x"00";    -- * 
		end case;
		return temp(6 downto 0);
	end function key2ascii;

	---------------------------------------------------------------

	function key_code2char(key_data : STD_LOGIC_VECTOR(7 downto 0)) return ascii2d is
	begin
	  case key_data is
		when "01000101" => return ('0', x"30"); -- 0
		when "00010110" => return ('1', x"31"); -- 1
		when "00011110" => return ('2', x"32"); -- 2
		when "00100110" => return ('3', x"33"); -- 3
		when "00100101" => return ('4', x"34"); -- 4
		when "00101110" => return ('5', x"35"); -- 5
		when "00110110" => return ('6', x"36"); -- 6
		when "00111101" => return ('7', x"37"); -- 7
		when "00111110" => return ('8', x"38"); -- 8
		when "01000110" => return ('9', x"39"); -- 9
			  --   --
		when "00011100" => return ('A', x"41"); -- A
		when "00110010" => return ('B', x"42"); -- B
		when "00100001" => return ('C', x"43"); -- C
		when "00100011" => return ('D', x"44"); -- D
		when "00100100" => return ('E', x"45"); -- E
		when "00101011" => return ('F', x"46"); -- F
		when "00110100" => return ('G', x"47"); -- G
		when "00110011" => return ('H', x"48"); -- H
		when "01000011" => return ('I', x"49"); -- I
		when "00111011" => return ('J', x"4A"); -- J
		when "01000010" => return ('K', x"4B"); -- K
		when "01001011" => return ('L', x"4C"); -- L
		when "00111010" => return ('M', x"4D"); -- M
		when "00110001" => return ('N', x"4E"); -- N
		when "01000100" => return ('O', x"4F"); -- O
		when "01001101" => return ('P', x"50"); -- P
		when "00010101" => return ('Q', x"51"); -- Q
		when "00101101" => return ('R', x"52"); -- R
		when "00011011" => return ('S', x"53"); -- S
		when "00101100" => return ('T', x"54"); -- T
		when "00111100" => return ('U', x"55"); -- U
		when "00101010" => return ('V', x"56"); -- V
		when "00011101" => return ('W', x"57"); -- W
		when "00100010" => return ('X', x"58"); -- X
		when "00110101" => return ('Y', x"59"); -- Y
		when "00011010" => return ('Z', x"5A"); -- Z
			  --   --
		when "00001110" => return ('`', x"60"); -- `
		when "01001110" => return ('-', x"2D"); -- -
		when "01010101" => return ('=', x"3D"); -- =
		when "01010100" => return ('[', x"5B"); -- [ 
		when "01011011" => return (']', x"5D"); -- ]
		when "01011101" => return ('\', x"08"); -- \
		when "01001100" => return (';', x"3B"); -- ;
		when "01010010" => return (''', x"27"); -- '
		when "01000001" => return (',', x"2C"); -- ,
		when "01001001" => return ('.', x"2E"); -- .
		when "01001010" => return ('/', x"2F"); -- /
			  --   --
		when "00000101" => return (' ', x"11"); -- (F1)
		when "00000110" => return (' ', x"12"); -- (F2)
		when "00000100" => return (' ', x"13"); -- (F3)
		when "00001100" => return (' ', x"14"); -- (F4)
		when "01110110" => return (' ', x"1B"); -- (ESC)
		when "00101001" => return (' ', x"20"); -- (space)
		when "01011010" => return ('$', x"0D"); -- (enter, cr)
		when "01100110" => return ('<', x"08"); -- (backspace)

		when others => return (' ', x"00");      -- * 
		
	  end case;
	end function key_code2char;

---------------------------------------------------------------

 -------------------------------
 function int2string(value : INTEGER) return STRING is
    variable res : STRING (1 to 4) := (others => NUL);
    variable hex_number : STD_LOGIC_VECTOR(15 downto 0);
  begin
 
    hex_number := STD_LOGIC_VECTOR(to_unsigned(value, hex_number'length));
    res(4) := nibble2char(hex_number(3 downto 0));
    res(3) := nibble2char(hex_number(7 downto 4));
    res(2) := nibble2char(hex_number(11 downto 8));
    res(1) := nibble2char(hex_number(15 downto 12));

    return res;
  end function int2string;

	function debug (param_name 	: string (1 to 10);	
	 				value		: integer) return string is

		variable res_line  : string (1 to 80);
		variable value_str : string (1 to 4);

	begin
		value_str := int2string(value);
		res_line := param_name & '-' &  value_str & "                                                                 "; 
		return res_line; 	
	end function debug;	

end package body;	
