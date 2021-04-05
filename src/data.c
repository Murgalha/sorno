#include <stdio.h>
#include <stdlib.h>
#include "data.h"

void target_free(Target *t) {
	if(!t) {
		return;
	}
	free(t->name);
	free(t->user);
	free(t->address);
	free(t->path);
	free(t);
}

void target_print(Target *target) {
	printf("Name: %s\n", target->name);
	printf("Address: %s\n", target->address);
	printf("User: %s\n", target->user);
	printf("Path: %s\n", target->path);
}

void element_free(Element *e) {
	if(!e) {
		return;
	}
	free(e->name);
	free(e->source);
	free(e->destination);
	free(e);
}

void element_print(Element *element) {
	printf("Name: %s\n", element->name);
	printf("Source: %s\n", element->source);
	printf("Destination: %s\n", element->destination);
}

void profile_free(Profile *p) {
	if(!p) {
		return;
	}
	free(p->name);
	for(int i = 0; i < p->n_elements; i++) {
		element_free((p->element) + i);
	}
	free(p);
}

void profile_print(Profile *p) {
	printf("Profile name: %s\n", p->name);
	printf("Elements:\n");
	for(int i = 0; i < p->n_elements; i++) {
		element_print((p->element) + i);
	}
}
