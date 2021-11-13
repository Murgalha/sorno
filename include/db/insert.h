#ifndef _DB_INSERT_H_
#define _DB_INSERT_H_

#include <sqlite3.h>
#include "data.h"

void db_insert_profile(sqlite3 *, Profile);
void db_insert_target(sqlite3 *, Target);
void db_insert_element(sqlite3 *, Element);
void db_link_element_to_profile(sqlite3 *, char *, char *);

#endif
