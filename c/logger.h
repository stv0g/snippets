#include <stdlib.h>
#include <sys/time.h>

#ifndef V
 #define V 5
#endif

#ifdef __GNUC__
 #define EXPECT(x, v)	__builtin_expect(x, v)
 #define INDENT		int __attribute__ ((__cleanup__(_outdent), unused)) _old_indent = _indent++; 
#else
 #define EXPECT(x, v)	(x)
 #define INDENT		;
#endif

/* These global variables allow changing the output style and verbosity */
extern int _debug;
extern int _indent;

void outdent(int *old);

/** The log level which is passed as first argument to print() */
enum log_level { DEBUG, INFO, WARN, ERROR };

/** Reset the timer for log outputs to zero. */
void log_reset();

/** Set the current logging level */
void log_level(int lvl);

/** Get delta between two timespec structs */
double timespec_delta(struct timeval *start, struct timeval *end);

/** Logs variadic messages to stdout.
 *
 * @param lvl The log level
 * @param fmt The format string (printf alike)
 */
void print(enum log_level lvl, const char *fmt, ...);

/** Check assertion and exit if failed. */
#define assert(exp) do { \
	if (EXPECT(!exp, 0)) { \
		print(ERROR, "Assertion failed: '%s' in %s, %s:%d", \
			#exp, __FUNCTION__, __BASE_FILE__, __LINE__); \
		exit(EXIT_FAILURE); \
	} } while (0)

/** Printf alike debug message with level. */
#define debug(lvl, msg, ...) do { \
	if (lvl <= _debug) \
		print(DEBUG, msg, ##__VA_ARGS__); \
	} while (0)

/** Printf alike info message. */
#define info(msg, ...) do { \
		print(INFO, msg, ##__VA_ARGS__); \
	} while (0)

/** Printf alike warning message. */
#define warn(msg, ...) do { \
		print(WARN, msg, ##__VA_ARGS__); \
	} while (0)

/** Print error and exit. */
#define error(msg, ...) do { \
		print(ERROR, msg, ##__VA_ARGS__); \
		exit(EXIT_FAILURE); \
	} while (0)

/** Print error and strerror(errno). */
#define serror(msg, ...) do { \
		print(ERROR, msg ": %s", ##__VA_ARGS__, \
			strerror(errno)); \
		exit(EXIT_FAILURE); \
	} while (0)

/** Print configuration error and exit. */
#define cerror(c, msg, ...) do { \
		print(ERROR, msg " in %s:%u", ##__VA_ARGS__, \
			(config_setting_source_file(c)) ? \
			 config_setting_source_file(c) : "(stdio)", \
			config_setting_source_line(c)); \
		exit(EXIT_FAILURE); \
	} while (0)