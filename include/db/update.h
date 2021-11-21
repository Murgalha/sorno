#ifndef _DB_UPDATE_H_
#define _DB_UPDATE_H_

#include <sqlite3.h>
#include "data.h"

void db_update_element(sqlite3 *, Element);
void db_update_target(sqlite3 *, Target);
void db_update_profile(sqlite3 *, Profile);

#endif
