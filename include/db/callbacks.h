#ifndef _DB_CALLBACKS_H_
#define _DB_CALLBACKS_H_

int db_select_target_callback(void *, int, char **, char **);
int db_select_profiles_callback(void *, int, char **, char **);
int db_select_profile_name_callback(void *, int, char **, char **);
int db_select_element_callback(void *, int, char **, char **);

#endif
