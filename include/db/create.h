#ifndef _DB_CREATE_H_
#define _DB_CREATE_H_

#include <sqlite3.h>

void mkdir_p(char *);
char *db_get_path();
sqlite3 *db_open();
void db_close(sqlite3 *);
void db_create_tables(sqlite3 *);

#endif
