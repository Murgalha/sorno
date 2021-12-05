#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include "db/callbacks.h"
#include "db/common.h"
#include "data.h"
#define MTB_STR_IMPLEMENTATION
#include "mtb_str.h"

//
// CALLBACKS
//
// For the select callbacks, since the functions are executed for each row of
// the query result, they simply allocate one more element on the array, set
// its data and return.
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
		else if(!strcmp(names[i], "id")) {
			t[*len].id = atoi(columns[i]);
		}
	}
	(*len)++;
	array->data = t;
	return 0;
}

int db_select_profiles_callback(void *arr, int ncols, char **columns, char **names) {
	Array *array = (Array *) arr;
	Profile *profile = (Profile *)array->data;
	int *len = &(array->len);
	bool already_added = false;
	char *profile_name = NULL;
	char *element_name = NULL;
	int profile_id;

	for(int i = 0; i < ncols; i++) {
		if(!strcmp(names[i], "name")) {
			profile_name = columns[i];
		}
		else if(!strcmp(names[i], "element")) {
			element_name = columns[i];
		}
		else if(!strcmp(names[i], "id")) {
			profile_id = atoi(columns[i]);
		}
	}

	for(int i = 0; i < *len; i++) {
		if(!strcmp(profile_name, profile[i].name) && element_name) {
			profile->element_names = realloc(profile->element_names, sizeof(char *) * (profile->n_elements + 1));
			profile->element_names[profile->n_elements] = mtbs_new(element_name);
			(profile->n_elements)++;
			return 0;
		}
	}

	profile = realloc(profile, sizeof(Profile) * ((*len) + 1));
	profile[*len].name = mtbs_new(profile_name);
	profile[*len].id = profile_id;
	profile[*len].n_elements = 0;
	profile[*len].element_names = NULL;

	if(element_name) {
		profile[*len].element_names = malloc(sizeof(char *));
		profile[*len].element_names[0] = mtbs_new(element_name);
	}
	array->data = profile;
	(*len)++;
  
	return 0;
}

int db_select_profile_name_callback(void *arr, int ncols, char **columns, char **names) {
	Array *array = (Array *) arr;
	Profile *p = (Profile *) array->data;
	unsigned int *len = &(array->len);
	p = realloc(p, sizeof(Profile) * (*len + 1));

	for(int i = 0; i < ncols; i++) {
		if(!strcmp(names[i], "name")) {
			p[*len].name = mtbs_new(columns[i]);
		}
		else if(!strcmp(names[i], "id")) {
			p[*len].id = atoi(columns[i]);
		}
	}
	(*len)++;
	array->data = p;
	return 0;
}

int db_select_element_callback(void *arr, int ncols, char **columns, char **names) {
	Array *array = (Array *) arr;
	Element *e = (Element *) array->data;
	unsigned int *len = &(array->len);
	e = realloc(e, sizeof(Element) * ((*len) + 1));

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
		else if(!strcmp(names[i], "id")) {
			e[*len].id = atoi(columns[i]);
		}
		else if(!strcmp(names[i], "profile_name")) {
			e[*len].profile = columns[i];
		}

	}
	(*len)++;
	array->data = e;
	return 0;
}
