-- Short description
--
-- Long description
--
-- @copyright	2016 Steffen Vogel
-- @license	http://www.gnu.org/licenses/gpl.txt GNU Public License
-- @author	Steffen Vogel <post@steffenvogel.de>
-- @link	http://www.steffenvogel.de
-- @package
-- @category
-- @since
--
--------------------------------------------------------------------------------
--
-- This file is part of [...]
--
-- [...] is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- any later version.
--
-- [...] is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with [...]. If not, see <http://www.gnu.org/licenses/>.
--------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_textio.all;
    use ieee.math_real.all;
    
library std;
    use std.textio.all;

entity name is
	generic (
	
	);
	port (
		clk				: in	std_logic;
		reset				: in	std_logic;

		input				: in	std_logic_vector(7 downto 0);
		output				: out	std_logic_vector(7 downto 0)
	)
end entity;


architecture rtl of name is
begin

end architecture;