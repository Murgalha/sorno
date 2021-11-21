#include <stdlib.h>
#include <stdio.h>
#include "db/insert.h"
#include "db/common.h"
#include "db/query_strings.h"

void db_insert_profile(sqlite3 *db, Profile profile) {
	char *str = db_generate_query_string(INSERT_PROFILE_NAME_QSTRING, profile.name);
	Array *array = db_execute_query(db, str, NULL);
	free(array);
	sqlite3_free(str);
	return;
}

void db_insert_target(sqlite3 *db, Target target) {
	char *str = db_generate_query_string(INSERT_TARGET_QSTRING, target.name, target.path, target.address, target.user);
	Array *array = db_execute_query(db, str, NULL);
	free(array);
	sqlite3_free(str);
	return;
}

void db_insert_element(sqlite3 *db, Element element) {
	char *str = db_generate_query_string(INSERT_ELEMENT_QSTRING, element.name, element.source, element.destination);
	Array *array = db_execute_query(db, str, NULL);
	free(array);
	sqlite3_free(str);
	return;
}

void db_link_element_to_profile(sqlite3 *db, char *element, char *profile) {
	char *str = db_generate_query_string(INSERT_PROFILEELEMENTS_QSTRING, profile, element);
	Array *array = db_execute_query(db, str, NULL);
	sqlite3_free(str);
	free(array);
	return;
}
