#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "db/callbacks.h"
#include "data.h"
#include "mtb_str.h"

void add_element_to_profile(Element e, Profile *p) {
	p->element = realloc(p->element, sizeof(Element) * (p->n_elements + 1));
	p->element[p->n_elements++] = e;
}

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
	}
	(*len)++;
	array->data = t;
	return 0;
}

int db_select_profiles_callback(void *arr, int ncols, char **columns, char **names) {
	char *profile_name;
	bool added = false;
	Element e;
	Array *array = (Array *) arr;
	Profile *p = (Profile *) array->data;
	unsigned int *len = &(array->len);

	for(int i = 0; i < ncols; i++) {
		if(!strcmp(names[i], "name")) {
			e.name = mtbs_new(columns[i]);
		}
		else if(!strcmp(names[i], "source")) {
			e.source = mtbs_new(columns[i]);
		}
		else if(!strcmp(names[i], "destination")) {
			e.destination = mtbs_new(columns[i]);
		}
		else if(!strcmp(names[i], "profile")) {
			profile_name = mtbs_new(columns[i]);
		}
	}

	// Checks if the profile already exists in the array
	// If not, it is then added
	for(int k = 0; k < *len; k++) {
		if(!strcmp(profile_name, p[k].name)) {
			add_element_to_profile(e, p+(k*sizeof(Profile)));
			added = true;
		}
	}
	if(!added) {
		p = realloc(p, sizeof(Profile) * (*len + 1));
		p[*len].n_elements = 0;
		p[*len].element = NULL;
		p[*len].name = profile_name;
		add_element_to_profile(e, p+((*len)*sizeof(Profile)));
		(*len)++;
		array->data = p;
	}

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
