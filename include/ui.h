#ifndef _UI_H_
#define _UI_H_

#include <sqlite3.h>
#include "data.h"

void clear_stdin();
char *file_read_line(FILE *);

//
// READ DATA
//
Target *ui_read_target();
Element *ui_read_element();
Profile *ui_read_profile();

//
// SELECT DATA
//
int ui_select_profile(char *, Profile *, int);
int ui_select_element(char *, Element *, int);
int ui_select_target(char *, Target *, int);


#endif
