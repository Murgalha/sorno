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

void target_print(Target target) {
	printf("Id: %d\n", target.id);
	printf("Name: %s\n", target.name);
	printf("Address: %s\n", target.address);
	printf("User: %s\n", target.user);
	printf("Path: %s\n", target.path);
}

void target_print_multiple(Target *targets, int n) {
	printf("%d Targets:\n", n);
    for(int i = 0; i < n; i++) {
        target_print(targets[i]);
    }
    printf("---\n");
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

void element_print(Element element) {
	printf("Id: %d\n", element.id);
	printf("Name: %s\n", element.name);
	printf("Source: %s\n", element.source);
	printf("Destination: %s\n", element.destination);
}

void element_print_multiple(Element *elements, int n) {
	printf("%d Elements:\n", n);
    for(int i = 0; i < n; i++) {
        element_print(elements[i]);
    }
    printf("---\n");
}

void profile_free(Profile *p) {
	if(!p) {
		return;
	}
	free(p->name);
	free(p);
}

void profile_print(Profile p) {
	printf("Profile name: %s\n", p.name);
	printf("Id: %d\n", p.id);
	printf("%d Elements:\n", p.n_elements);
	for(int i = 0; i < p.n_elements; i++) {
		printf("  - '%s'\n", p.element_names[i]);
	}
	printf("\n");
}

void profile_print_multiple(Profile *profiles, int n) {
	printf("%d Profiles:\n", n);
    for(int i = 0; i < n; i++) {
        profile_print(profiles[i]);
    }
    printf("---\n");
}
