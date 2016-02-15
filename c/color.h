/** Various helper functions.
 *
 * @author Steffen Vogel <stvogel@eonerc.rwth-aachen.de>
 * @copyright 2014, Institute for Automation of Complex Power Systems, EONERC
 * @file
 */

#ifndef _COLOR_H_
#define _COLOR_H_

#include <stdlib.h>
#include <stdarg.h>
#include <errno.h>
#include <string.h>

/* Some color escape codes for pretty log messages */
#define GRY(str)	"\e[30m" str "\e[0m" /**< Print str in gray */
#define RED(str)	"\e[31m" str "\e[0m" /**< Print str in red */
#define GRN(str)	"\e[32m" str "\e[0m" /**< Print str in green */
#define YEL(str)	"\e[33m" str "\e[0m" /**< Print str in yellow */
#define BLU(str)	"\e[34m" str "\e[0m" /**< Print str in blue */
#define MAG(str)	"\e[35m" str "\e[0m" /**< Print str in magenta */
#define CYN(str)	"\e[36m" str "\e[0m" /**< Print str in cyan */
#define WHT(str)	"\e[37m" str "\e[0m" /**< Print str in white */
#define BLD(str)	"\e[1m"  str "\e[0m" /**< Print str in bold */

#define GFX(chr)	"\e(0" chr "\e(B"
#define UP(n)		"\e[" ## n ## "A"
#define DOWN(n)	 	"\e[" ## n ## "B"
#define RIGHT(n)	"\e[" ## n ## "C"
#define LEFT(n)	 	"\e[" ## n ## "D"

#endif /* _COLOR_H_ */
