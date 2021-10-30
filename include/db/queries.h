#ifndef _DB_QUERIES_H_
#define _DB_QUERIES_H_

#include <sqlite3.h>
#include "data.h"

Profile *db_select_profiles(sqlite3 *, int *);
Target *db_select_targets(sqlite3 *, int *);
Profile *db_select_profile_names(sqlite3 *, int *);
Profile *db_select_profile(sqlite3 *, char *);
Element *db_select_unlinked_elements(sqlite3 *, int *);
Element *db_select_elements(sqlite3 *, int *);
void db_insert_profile(sqlite3 *, Profile *);
void db_insert_element(sqlite3 *, Element *);
void db_insert_target(sqlite3 *, Target *);
void db_link_element(sqlite3 *, Element *, Profile *);

#endif
