#include <stdio.h>
#include "db/queries.h"
#include "db/callbacks.h"
#define MTB_STR_IMPLEMENTATION
#include "mtb_str.h"

//
// SELECT
//
Profile *db_select_profiles(sqlite3 *db, int *n) {
	Array arr = { NULL, 0 };
	char *errmsg;
	char *sql = "SELECT * FROM element e JOIN profileelements pe "
		"WHERE e.name = pe.element;";
	sqlite3_exec(db, sql, db_select_profiles_callback, &arr, &errmsg);
	Profile *p = arr.data;
	*n = arr.len;

	//sqlite3_free(sql);
	//sqlite3_free(errmsg);
	return p;
}

Target *db_select_targets(sqlite3 *db, int *n) {
	Array arr = { NULL, 0 };
	char *errmsg;
	char *sql = "SELECT * FROM target;";
	sqlite3_exec(db, sql, db_select_target_callback, &arr, &errmsg);

	Target *t = arr.data;
	*n = arr.len;

	//sqlite3_free(sql);
	//sqlite3_free(errmsg);
	return t;
}

Profile *db_select_profile_names(sqlite3 *db, int *n) {
	Array arr = { NULL, 0 };
	char *errmsg;
	char *sql = "SELECT * FROM profile;";
	sqlite3_exec(db, sql, db_select_profile_name_callback, &arr, &errmsg);

	Profile *p = arr.data;
	p->n_elements = 0;
	p->element = NULL;
	*n = arr.len;

	//sqlite3_free(sql);
	//sqlite3_free(errmsg);
	return p;
}

Profile *db_select_profile(sqlite3 *db, char *profile_name) {
	Array arr = { NULL, 0 };
	char *errmsg;
	char *sql = sqlite3_mprintf("SELECT * FROM element as e JOIN "		\
								"profileelements as pe ON e.name = pe.element "	\
								"WHERE pe.profile = %Q;", profile_name);
	sqlite3_exec(db, sql, db_select_element_callback, &arr, &errmsg);

	Profile *prof = malloc(sizeof(Profile));
	prof->name = mtbs_new(profile_name);
	prof->element = arr.data;
	prof->n_elements = arr.len;

	//sqlite3_free(sql);
	//sqlite3_free(errmsg);
	return prof;
}

Element *db_select_unlinked_elements(sqlite3 *db, int *n) {
	Array arr = { NULL, 0 };
	char *errmsg;
	char *sql = "SELECT * FROM element WHERE name "		\
		"NOT IN(SELECT element FROM profileelements)";
	sqlite3_exec(db, sql, db_select_element_callback, &arr, &errmsg);

	Element *e = arr.data;
	*n = arr.len;

	//sqlite3_free(sql);
	//sqlite3_free(errmsg);
	return e;
}

Element *db_select_elements(sqlite3 *db, int *n) {
	Array arr = { NULL, 0 };
	char *errmsg;
	char *sql = "SELECT * FROM element;";
	sqlite3_exec(db, sql, db_select_element_callback, &arr, &errmsg);

	Element *e = arr.data;
	*n = arr.len;

	//sqlite3_free(sql);
	//sqlite3_free(errmsg);
	return e;
}

//
// INSERT
//
void db_insert_profile(sqlite3 *db, Profile *p) {
	char *errmsg;
	char *sql = sqlite3_mprintf("INSERT INTO profile VALUES(%Q);",
								p->name);
	if(!sql) {
		printf("Could not generate INSERT INTO PROFILE query string\n");
	}
	sqlite3_exec(db, sql, NULL, 0, &errmsg);
	sqlite3_free(errmsg);
	sqlite3_free(sql);
}

void db_insert_element(sqlite3 *db, Element *e) {
	char *errmsg;
	char *sql = sqlite3_mprintf("INSERT INTO element VALUES(%Q, %Q, %Q);",
								e->name, e->source, e->destination);
	if(!sql) {
		printf("Could not generate INSERT INTO ELEMENT query string\n");
		sqlite3_free(errmsg);
		sqlite3_free(sql);
		return;
	}
	sqlite3_exec(db, sql, NULL, 0, &errmsg);
	sqlite3_free(errmsg);
	sqlite3_free(sql);
}

void db_insert_target(sqlite3 *db, Target *t) {
	char *errmsg;
	char *sql = sqlite3_mprintf("INSERT INTO target VALUES(%Q, %Q, %Q, %Q);",
								t->name, t->path, t->address, t->user);
	if(!sql) {
		printf("Could not generate INSERT INTO TARGET query string\n");
		sqlite3_free(errmsg);
		sqlite3_free(sql);
		return;
	}
	sqlite3_exec(db, sql, NULL, 0, &errmsg);
	sqlite3_free(errmsg);
	sqlite3_free(sql);
}

void db_link_element(sqlite3 *db, Element *e, Profile *p) {
	char *errmsg;
	char *sql = sqlite3_mprintf("INSERT INTO profileelements VALUES(%Q, %Q);", p->name, e->name);
	if(!sql) {
		printf("Could not generate INSERT INTO PROFILEELEMENTS query string\n");
		sqlite3_free(errmsg);
		sqlite3_free(sql);
		return;
	}
	sqlite3_exec(db, sql, NULL, 0, &errmsg);
	sqlite3_free(errmsg);
	sqlite3_free(sql);
}
