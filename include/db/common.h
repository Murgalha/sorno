#ifndef _COMMON_H_
#define _COMMON_H_

#include <sqlite3.h>

// Array struct to keep track of number of elements
// inside sqlite callback
typedef struct {
	void *data;
	unsigned int len;
} Array;

Array *db_execute_query(sqlite3 *, const char *, int (*callback)(void*,int,char**,char**));
char *db_generate_query_string(const char *, ...);

#endif
