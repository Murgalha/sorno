#ifndef _DB_H_
#define _DB_H_

#include <sqlite3.h>
#include "data.h"

char *db_get_path();
sqlite3 *db_open();
void db_close(sqlite3 *);
void db_create_tables(sqlite3 *);

// Select elements
Target *db_select_targets(sqlite3 *, int *);
Profile *db_select_profile_names(sqlite3 *, int *);
Element *db_select_unlinked_elements(sqlite3 *, int *);
Profile *db_select_profile(sqlite3 *, char *);

// Insert elements
void db_insert_profile(sqlite3 *, Profile *);
void db_insert_element(sqlite3 *, Element *);
void db_insert_target(sqlite3 *, Target *);
void db_link_element(sqlite3 *, Element *, Profile *);

#endif
