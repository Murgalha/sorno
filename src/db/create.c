#include <dirent.h>
#include <errno.h>
#include <sys/stat.h>
#include <stdio.h>
#include "db/create.h"
#include "mtb_str.h"

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
