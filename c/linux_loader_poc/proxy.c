/** Proof-of-concept to show different methods to load executables in the Linux kernel
 *
 * @copyright	2016 Steffen Vogel
 * @license	http://www.gnu.org/licenses/gpl.txt GNU Public License
 * @author	Steffen Vogel <post@steffenvogel.de>
 * @link	http://www.steffenvogel.de
 */

#include <unistd.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
	printf("This is the dynamically-linked proxy: %s\n", argv[0]);
	printf("  Running now /usr/bin/objdump -dS %s\n\n", argv[1]);

	execl("/usr/bin/objdump", "objdump", "-dS", argv[0], NULL);
}
