#ifndef _DATA_H_
#define _DATA_H_

typedef struct {
	int id;
	char *name;
	char *source;
	char *destination;
	char *profile;
} Element;

typedef struct {
	int id;
	char *name;
	unsigned int n_elements;
	char **element_names;
} Profile;

typedef struct {
	int id;
	char *name;
	char *user;
	char *address;
	char *path;
} Target;

void target_free(Target *);
void target_print(Target);
void target_print_multiple(Target *, int);

void element_free(Element *);
void element_print(Element);
void element_print_multiple(Element *, int);

void profile_free(Profile *);
void profile_print(Profile);
void profile_print_multiple(Profile *, int);


#endif
