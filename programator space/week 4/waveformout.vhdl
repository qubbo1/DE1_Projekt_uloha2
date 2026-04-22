process(SW)
begin
    case SW is

        -- square → RED
        when "00" =>
            led16_r <= '1';
            led16_g <= '0';
            led16_b <= '0';

        -- triangle → GREEN
        when "01" =>
            led16_r <= '0';
            led16_g <= '1';
            led16_b <= '0';

        -- sawtooth → BLUE
        when "10" =>
            led16_r <= '0';
            led16_g <= '0';
            led16_b <= '1';

        -- sine → YELLOW (R + G)
        when "11" =>
            led16_r <= '1';
            led16_g <= '1';
            led16_b <= '0';

        when others =>
            led16_r <= '0';
            led16_g <= '0';
            led16_b <= '0';

    end case;
end process;
