#include <dirent.h>
#include <errno.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <stdio.h>
#include "db.h"
#define MTB_STR_IMPLEMENTATION
#include "mtb_str.h"

// Array struct to keep track of number of elements
// inside sqlite callback
typedef struct {
	void *data;
	unsigned int len;
} Array;

//
// CALLBACKS
//
int db_select_target_callback(void *arr, int ncols, char **columns, char **names) {
	Array *array = (Array *) arr;
	Target *t = (Target *) array->data;
	unsigned int *len = &(array->len);
	t = realloc(t, sizeof(Target) * (*len + 1));

	for(int i = 0; i < ncols; i++) {
		if(!strcmp(names[i], "name")) {
			t[*len].name = mtbs_new(columns[i]);
		}
		else if(!strcmp(names[i], "path")) {
			t[*len].path = mtbs_new(columns[i]);
		}
		else if(!strcmp(names[i], "address")) {
			t[*len].address = mtbs_new(columns[i]);
		}
		else if(!strcmp(names[i], "user")) {
			t[*len].user = mtbs_new(columns[i]);
		}
	}
	(*len)++;
	array->data = t;
	return 0;
}

int db_select_profile_name_callback(void *arr, int ncols, char **columns, char **names) {
	Array *array = (Array *) arr;
	Profile *p = (Profile *) array->data;
	unsigned int *len = &(array->len);
	p = realloc(p, sizeof(Profile) * (*len + 1));

	for(int i = 0; i < ncols; i++) {
		p[*len].name = mtbs_new(columns[i]);
	}
	(*len)++;
	array->data = p;
	return 0;
}

int db_select_element_callback(void *arr, int ncols, char **columns, char **names) {
	Array *array = (Array *) arr;
	Element *e = (Element *) array->data;
	unsigned int *len = &(array->len);
	e = realloc(e, sizeof(Element) * (*len + 1));

	for(int i = 0; i < ncols; i++) {
		if(!strcmp(names[i], "name")) {
			e[*len].name = mtbs_new(columns[i]);
		}
		else if(!strcmp(names[i], "source")) {
			e[*len].source = mtbs_new(columns[i]);
		}
		else if(!strcmp(names[i], "destination")) {
			e[*len].destination = mtbs_new(columns[i]);
		}
	}
	(*len)++;
	array->data = e;
	return 0;
}

void mkdir_p(char *path) {
	int n;
	char **tokens = mtbs_split(path, &n, "/");
	char *full_path = mtbs_new("/");

	for(int i = 0; i < n; i++) {
		mtbs_concat(3, &full_path, tokens[i], "/");

		DIR* dir = opendir(full_path);
		if(dir) {
			closedir(dir);
		}
		else if(ENOENT == errno) {
			mkdir(full_path, 0777);
		} else {
			printf("Could not create directory %s\n", full_path);
		}
	}
	free(full_path);
	mtbs_free_split(tokens, n);
}

char *db_get_path() {
	char *data_dir = getenv("XDG_DATA_HOME");
	char *path;

	if(data_dir) {
		path = mtbs_join(2, data_dir, "/sorno/db");
	}
	else {
		data_dir = getenv("HOME");
		path = mtbs_join(2, data_dir, "/.local/share/sorno/db");
	}
	return path;
}

sqlite3 *db_open() {
	char *path = db_get_path();
	char *db_name = mtbs_join(2, path, "/sorno.db");

	mkdir_p(path);

	sqlite3 *db;
	int res = sqlite3_open(db_name, &db);

	if(res != SQLITE_OK) {
		printf("Could not open database connection: %s\n", sqlite3_errmsg(db));
	}

	db_create_tables(db);

	free(path);
	free(db_name);
	return db;
}

void db_close(sqlite3 *db) {
	sqlite3_close(db);
}

void db_create_tables(sqlite3 *db) {
   int rc;
   char *sql, *errmsg;
   // TODO: Error handling
   sql = "CREATE TABLE IF NOT EXISTS profile("	\
	   "name TEXT PRIMARY KEY);";
   rc = sqlite3_exec(db, sql, NULL, 0, &errmsg);
   sqlite3_free(errmsg);

   sql = "CREATE TABLE IF NOT EXISTS target("	\
	   "name TEXT PRIMARY KEY,"					\
	   "path TEXT NOT NULL,"					\
	   "address TEXT,"							\
	   "user TEXT);";
   rc = sqlite3_exec(db, sql, NULL, 0, &errmsg);
   sqlite3_free(errmsg);

   sql = "CREATE TABLE IF NOT EXISTS element("	\
	   "name TEXT PRIMARY KEY NOT NULL,"		\
	   "source TEXT NOT NULL,"					\
	   "destination TEXT NOT NULL);";
   rc = sqlite3_exec(db, sql, NULL, 0, &errmsg);
   sqlite3_free(errmsg);

   sql = "CREATE TABLE IF NOT EXISTS profileelements("		\
	   "profile TEXT NOT NULL,"								\
	   "element TEXT NOT NULL,"								\
	   "FOREIGN KEY(profile) REFERENCES profile(name),"		\
	   "FOREIGN KEY(element) REFERENCES element(name),"		\
	   "PRIMARY KEY(profile, element));";

   rc = sqlite3_exec(db, sql, NULL, 0, &errmsg);
   sqlite3_free(errmsg);
}

//
// SELECT
//
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
