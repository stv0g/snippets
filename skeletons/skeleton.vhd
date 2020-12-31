-- Short description
--
-- Long description
--
-- @copyright 2021, Steffen Vogel
-- @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
-- @author    Steffen Vogel <post@steffenvogel.de>
-- @link      https://www.steffenvogel.de
-- @package
-- @category
-- @since
--
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
