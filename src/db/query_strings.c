#include "db/query_strings.h"

const char *SELECT_ALL_PROFILES_QSTRING = "SELECT * FROM profile p "
	"LEFT JOIN profileelements pe ON p.name = pe.profile;";
const char *SELECT_ALL_TARGETS_QSTRING = "SELECT * FROM target;";
const char *SELECT_ALL_ELEMENTS_QSTRING = "SELECT * FROM element e JOIN profileelements "
	"pe ON e.name = pe.element;";
const char *SELECT_PROFILE_QSTRING = "SELECT * FROM element as e JOIN "
	"profileelements as pe ON e.name = pe.element "
	"WHERE pe.profile = %Q;";

const char *INSERT_TARGET_QSTRING = "INSERT INTO target VALUES(%Q, %Q, %Q, %Q);";
const char *INSERT_ELEMENT_QSTRING = "INSERT INTO element VALUES(%Q, %Q, %Q);";
const char *LINK_ELEMENT_QSTRING = "INSERT INTO profileelements VALUES(%Q, %Q);";
const char *INSERT_PROFILE_NAME_QSTRING = "INSERT INTO profile VALUES(%Q);";
