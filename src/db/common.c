#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "db/common.h"

Array *db_execute_query(sqlite3 *db, const char *query, int (*callback)(void*,int,char**,char**)) {
	Array *array = calloc(1, sizeof(Array));
	char *errmsg;

	sqlite3_exec(db, query, callback, array, &errmsg);
	return array;
}

char *db_generate_query_string(const char *query_string, ...) {
	va_list args;
	va_start(args, query_string);

	char *sql = sqlite3_vmprintf(query_string, args);
	if(!sql) {
		printf("Could not generate '%s'\n", query_string);
		return NULL;
	}
	va_end(args);
	printf("Query string: '%s'\n", sql);

	return sql;
}
