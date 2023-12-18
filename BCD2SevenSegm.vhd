library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity BCD2SevenSegm is
    port ( BCD: in unsigned(3 downto 0);
           SevenSegm: out std_logic_vector(6 downto 0)
           );
end BCD2SevenSegm;

architecture Behavioral of BCD2SevenSegm is
 
begin
    process(BCD)
    begin
        case BCD is
            when "0000" => SevenSegm <= "0000001"; ---0 op 7segment display
            when "0001" => SevenSegm <= "1001111"; ---1
            when "0010" => SevenSegm <= "0010010"; ---2
            when "0011" => SevenSegm <= "0000110"; ---3
            when "0100" => SevenSegm <= "1001100"; ---4
            when "0101" => SevenSegm <= "0100100"; ---5
            when "0110" => SevenSegm <= "0100000"; ---6
            when "0111" => SevenSegm <= "0001111"; ---7
            when "1000" => SevenSegm <= "0000000"; ---8
            when "1001" => SevenSegm <= "0000100"; ---9
            when others => SevenSegm <= "0110000"; ---E
        end case;
    end process;
end Behavioral;