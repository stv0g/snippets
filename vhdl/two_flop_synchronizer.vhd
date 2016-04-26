-- Two-Flop Synchronizer
--
--------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;

entity two_flop_synchronizer is
	generic (
		-- 4 ns for backward compatibility with spartan3
		META_FFS_MAXDELAY		: string := "4.8 ns"
	);
	port (
		i_clk				: in	std_logic; -- destination clock
		i_signal			: in	std_logic; -- input
		o_signal			: out	std_logic  -- output
	);
end entity;

architecture rtl of two_flop_synchronizer is
	signal meta_signal			: std_logic := '0';
	signal meta_signal_1d			: std_logic := '0';
		
	attribute MAXDELAY			: string;
	attribute ASYNC_REG			: string;

	attribute MAXDELAY of meta_signal	: signal is META_FFS_MAXDELAY;
	attribute ASYNC_REG of meta_signal	: signal is "TRUE";
	attribute ASYNC_REG of meta_signal_1d	: signal is "TRUE";
begin
	o_signal <= meta_signal_1d;

	process(i_clk)
	begin
		if rising_edge(i_clk) then
			meta_signal		<= i_signal;
			meta_signal_1d		<= meta_signal;
		end if;
	end process;
end architecture;