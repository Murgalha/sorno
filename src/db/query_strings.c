#include "db/query_strings.h"

const char *CREATE_TARGET_QSTRING = "CREATE TABLE IF NOT EXISTS target("
	"id INTEGER PRIMARY KEY AUTOINCREMENT,"
	"name TEXT NOT NULL UNIQUE,"
	"path TEXT NOT NULL,"
	"address TEXT,"
	"user TEXT);";

const char *CREATE_PROFILE_QSTRING = "CREATE TABLE IF NOT EXISTS profile("
	"id INTEGER PRIMARY KEY AUTOINCREMENT,"
	"name TEXT NOT NULL UNIQUE);";

const char *CREATE_ELEMENT_QSTRING = "CREATE TABLE IF NOT EXISTS element("
	"id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,"
	"name TEXT NOT NULL UNIQUE,"
	"source TEXT NOT NULL,"
	"destination TEXT NOT NULL);";

const char *CREATE_PROFILEELEMENTS_QSTRING = "CREATE TABLE IF NOT EXISTS profileelements("
	"id INTEGER PRIMARY KEY AUTOINCREMENT,"
	"profile_id INTEGER NOT NULL,"
	"element_id INTEGER NOT NULL,"
	"FOREIGN KEY(profile_id) REFERENCES profile(id),"
	"FOREIGN KEY(element_id) REFERENCES element(id));";

const char *SELECT_ALL_PROFILES_QSTRING = "SELECT p.id, p.name, e.name as element "
	"FROM profile p "
	"LEFT JOIN profileelements pe ON p.id = pe.profile_id "
	"LEFT JOIN element e ON e.id = pe.element_id;";
const char *SELECT_ALL_TARGETS_QSTRING = "SELECT id, name, address, path, user FROM target;";
const char *SELECT_ALL_ELEMENTS_QSTRING = "SELECT e.name, e.id, e.source, e.destination, p.name as profile_name "
	"FROM element e "
	"LEFT JOIN profileelements pe ON e.id = pe.element_id "
	"LEFT JOIN profile p ON pe.element_id = p.id;";
const char *SELECT_PROFILE_QSTRING = "SELECT * FROM element as e JOIN "
	"profileelements as pe ON e.id = pe.element_id "
	"WHERE pe.profile_id = %u;";

const char *INSERT_ELEMENT_QSTRING = "INSERT INTO element(name, source, destination) VALUES(%Q, %Q, %Q);";
const char *INSERT_TARGET_QSTRING = "INSERT INTO target(name, path, address, user) VALUES(%Q, %Q, %Q, %Q);";
const char *INSERT_PROFILEELEMENTS_QSTRING = "INSERT INTO profileelements(profile, element) VALUES(%Q, %Q);";
const char *INSERT_PROFILE_NAME_QSTRING = "INSERT INTO profile(name) VALUES(%Q);";

const char *SELECT_SINGLE_ELEMENT_QSTRING = "SELECT * from element e WHERE e.id = %u;";
const char *SELECT_SINGLE_TARGET_QSTRING = "SELECT * from target t WHERE t.id = %u;";
const char *SELECT_SINGLE_PROFILE_QSTRING = "SELECT * from profile p WHERE p.id = %u;";

const char *UPDATE_SINGLE_ELEMENT_QSTRING = "UPDATE element SET name = %Q, source = %Q, destination = %Q "
	"WHERE id = %u;";
const char *UPDATE_SINGLE_TARGET_QSTRING = "UPDATE target SET name = %Q, path = %Q, address = %Q, user = %Q "
	"WHERE id = %u;";
const char *UPDATE_SINGLE_PROFILE_QSTRING = "UPDATE profile SET name = %Q WHERE id = %u;";
const char *UPDATE_SINGLE_PROFILEELEMENTS_QSTRING = "UPDATE profileelements SET profile = %Q, element = %Q WHERE id = %u;";
