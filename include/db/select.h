#ifndef _DB_SELECT_H_
#define _DB_SELECT_H_

#include <sqlite3.h>
#include "data.h"

Profile *db_select_all_profiles(sqlite3 *, int *);
Target *db_select_all_targets(sqlite3 *, int *);
Element *db_select_all_elements(sqlite3 *, int *);
Profile *db_select_single_profile(sqlite3 *, char *, int *);

#endif
