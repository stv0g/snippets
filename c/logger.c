#include <stdio.h>

#include "color.h"
#include "logger.h"

/* This global variable contains the debug level for debug() and assert() macros */
int _debug = V;
int _indent = 0;

static struct timeval epoch;

void _outdent(int *old)
{
	_indent = *old;
}

void log_reset()
{
	gettimeofday(&epoch, NULL);
}

void log_level(int lvl)
{
	_debug = lvl;
}

void print(enum log_level lvl, const char *fmt, ...)
{
	struct timeval tv;

	va_list ap;
	va_start(ap, fmt);

	/* Timestamp */
	gettimeofday(&tv, NULL);
	
	fprintf(stderr, "%8.3f ", timespec_delta(&epoch, &tv));

	switch (lvl) {
		case DEBUG: fprintf(stderr, BLD("%-5s "), GRY("Debug")); break;
		case INFO:  fprintf(stderr, BLD("%-5s "), WHT(" Info")); break;
		case WARN:  fprintf(stderr, BLD("%-5s "), YEL(" Warn")); break;
		case ERROR: fprintf(stderr, BLD("%-5s "), RED("Error")); break;
	}

	if (_indent) {
		for (int i = 0; i < _indent-1; i++)
			fprintf(stderr, GFX("\x78") " ");

		fprintf(stderr, GFX("\x74") " ");
	}

	vfprintf(stderr, fmt, ap);
	fprintf(stderr, "\n");

	va_end(ap);
}

double timespec_delta(struct timeval *start, struct timeval *end)
{
	double sec  = end->tv_sec - start->tv_sec;
	double usec = end->tv_usec - start->tv_usec;

	if (usec < 0) {
		sec  -= 1;
		usec += 1e6;
	}

	return sec + usec * 1e-6;
}