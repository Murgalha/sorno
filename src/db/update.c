#include <stdlib.h>
#include "db/update.h"
#include "db/query_strings.h"
#include "db/common.h"

void db_update_element(sqlite3 *db, Element e) {
	char *str = db_generate_query_string(UPDATE_SINGLE_ELEMENT_QSTRING, e.name, e.source, e.destination, e.id);
	Array *array = db_execute_query(db, str, NULL);
	free(array);
}

void db_update_target(sqlite3 *db, Target t) {
	char *str = db_generate_query_string(UPDATE_SINGLE_TARGET_QSTRING, t.name, t.path, t.address, t.user, t.id);
	Array *array = db_execute_query(db, str, NULL);
	free(array);
}

void db_update_profile(sqlite3 *db, Profile p) {
	char *str = db_generate_query_string(UPDATE_SINGLE_PROFILE_QSTRING, p.name, p.id);
	Array *array = db_execute_query(db, str, NULL);
	free(array);
}
