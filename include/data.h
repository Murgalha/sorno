#ifndef _DATA_H_
#define _DATA_H_

typedef struct {
	char *name;
	char *source;
	char *destination;
} Element;

typedef struct {
	char *name;
	unsigned int n_elements;
	Element *element;
} Profile;

typedef struct {
	char *name;
	char *user;
	char *address;
	char *path;
} Target;

void target_free(Target *);
void target_print(Target *);

void element_free(Element *);
void element_print(Element *);

void profile_free(Profile *);
void profile_print(Profile *);

#endif
