#ifndef _DB_CALLBACKS_H_
#define _DB_CALLBACKS_H_

// Array struct to keep track of number of elements
// inside sqlite callback
typedef struct {
	void *data;
	unsigned int len;
} Array;

int db_select_target_callback(void *, int, char **, char **);
int db_select_profiles_callback(void *, int, char **, char **);
int db_select_profile_name_callback(void *, int, char **, char **);
int db_select_element_callback(void *, int, char **, char **);

#endif
