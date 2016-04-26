-- Various smaller helpers
--
--------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;

package helpers is
	-- Types
	type axis_data is array (integer range <>) of std_logic_vector(31 downto 0);

	type axis_bus is record
		tdata					: std_logic_vector(31 downto 0);
		tvalid					: std_logic;
		tlast					: std_logic;
		tready					: std_logic;
	end record;

	-- Case boolean to std_logic
	function to_std_logic(value : boolean) return std_ulogic;

	-- Wait for c_cycles cylces of i_clk
	procedure wait_clk (
		signal i_clk				: in std_logic;
		constant c_cycles			: in integer
	);

	-- Toggle pin io_toggle for 1 cycle of i_clk
	procedure toggle (
		signal i_clk				: in std_logic;
		signal io_toggle			: inout std_logic
	);

	-- Trigger active-low reset for signal reset
	procedure reset (
		signal reset				: out std_logic
	);

	-- Pseudo AXI Stream Master BFM
	procedure axis_send (
		signal i_clk				: in std_logic;
		constant i_data				: in axis_data;
		signal axis_tdata			: out std_logic_vector(31 downto 0);
		signal axis_tvalid			: out std_logic;
		signal axis_tlast			: out std_logic;
		signal axis_tready			: in std_logic
	);

	-- Pseudo AXI Steam Slave BFM
	procedure axis_recv (
		signal i_clk				: in std_logic;
		signal axis_tdata			: in std_logic_vector(31 downto 0);
		signal axis_tvalid			: in std_logic;
		signal axis_tlast			: in std_logic;
		signal axis_tready			: out std_logic
	);
end package;

package body helpers is
	procedure wait_clk (
		signal i_clk				: in std_logic;
		constant c_cycles			: in integer
	) is
	begin
		for I in 1 to c_cycles loop
			wait until rising_edge(i_clk);
		end loop;
	end procedure;

	procedure toggle (
		signal i_clk				: in std_logic;
		signal io_toggle			: inout std_logic
	) is
	begin
		io_toggle				<= io_toggle xor '1';
		wait_clk(i_clk, 1);
		io_toggle				<= io_toggle xor '1';
	end procedure;

	procedure reset (
		signal reset				: out std_logic
	) is
	begin
		reset					<= '0';
		wait for 5 ns;
		reset					<= '1';
	end procedure;

	procedure axis_send (
		signal i_clk				: in std_logic;
		constant i_data				: in axis_data;
		signal axis_tdata			: out std_logic_vector(31 downto 0);
		signal axis_tvalid			: out std_logic;
		signal axis_tlast			: out std_logic;
		signal axis_tready			: in std_logic
	) is
	begin
		for i in i_data'range loop
			wait until rising_edge(i_clk) and axis_tready = '1';
			axis_tvalid			<= '1';
			axis_tdata			<= i_data(i);

			if i = i_data'high then
				axis_tlast		<= '1';
			else
				axis_tlast		<= '0';
			end if;
		end loop;

		wait until rising_edge(i_clk);
		axis_tvalid <= '0';
		axis_tlast <= '0';
	end procedure;

	procedure axis_recv (
		signal i_clk				: in std_logic;
		signal axis_tdata			: in std_logic_vector(31 downto 0);
		signal axis_tvalid			: in std_logic;
		signal axis_tlast			: in std_logic;
		signal axis_tready			: out std_logic
	) is
	begin
		axis_tready				<= '1';

		loop
			wait until rising_edge(i_clk) and axis_tvalid = '1';

			if axis_tlast = '1' then
				exit;
			end if;
		end loop;
	end procedure;

	function to_std_logic(value : boolean) return std_ulogic is
	begin
		if value then
			return('1');
		else
			return('0');
		end if;
	end function;

end package body;