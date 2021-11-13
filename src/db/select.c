#include <stdlib.h>
#include "db/select.h"
#include "db/query_strings.h"
#include "db/common.h"
#include "db/callbacks.h"

Profile *db_select_all_profiles(sqlite3 *db, int *n) {
	char *str = db_generate_query_string(SELECT_ALL_PROFILES_QSTRING);
	Array *array = db_execute_query(db, str, db_select_profiles_callback);
	Profile *p = array->data;
	*n = array->len;
	free(array);
	sqlite3_free(str);
	return p;
}

Target *db_select_all_targets(sqlite3 *db, int *n) {
	char *str = db_generate_query_string(SELECT_ALL_TARGETS_QSTRING);
	Array *array = db_execute_query(db, str, db_select_target_callback);
	Target *t = array->data;
	*n = array->len;
	free(array);
	sqlite3_free(str);
	return t;
}

Element *db_select_all_elements(sqlite3 *db, int *n) {
	char *str = db_generate_query_string(SELECT_ALL_ELEMENTS_QSTRING);
	Array *array = db_execute_query(db, str, db_select_element_callback);
	Element *e = array->data;
	*n = array->len;
	free(array);
	sqlite3_free(str);
	return e;
}

Profile *db_select_single_profile(sqlite3 *db, char *name, int *n) {
	char *str = db_generate_query_string(SELECT_PROFILE_QSTRING, name);
	Array *array = db_execute_query(db, str, db_select_profiles_callback);
	Profile *p = array->data;
	*n = array->len;
	sqlite3_free(str);
	free(array);
	return p;
}
