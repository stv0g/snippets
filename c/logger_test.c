#include <unistd.h>

#include "logger.h"

void recursive(int i)
{ INDENT
	info("We are inside the recursive function. Current level = %d", i);

	if (i) {
		usleep(rand() * 3e6 / RAND_MAX);
		recursive(i-1);
	}
}

void goodbye()
{
	warn("There was an error message. Program terminating...");
}

int main(int argc, char *argv[])
{
	/* Reset log timer to zero */
	epoch_reset();
	
	/* Register exit() handler */
	atexit(goodbye);
	
	info("Welcome, this is a little program to demo the logger");

	recursive(5);

	/* Some other types of messages */
	info("This is a info message");
	warn("This is a warning message");
	
	/* Debug messages are only printed if the level (1st arg) is higher than the current level */
	debug(3, "This is a debug message");
	
	/* INDENT's are valid per code block */
	{ INDENT
		info("This is an indented message");
	}

	/* Error messages will cause program termination */
	error("This is an error message");
	
	return 0;
}