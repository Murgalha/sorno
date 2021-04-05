#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include "ui.h"
#include "db.h"
#include "mtb_str.h"

void clear_stdin() {
	char c;
	do {
		c = fgetc(stdin);
	} while(c != '\n' && c != EOF);
}

char *basename(char *path) {
	int n;
	char **tokens = mtbs_split(path, &n, "/");
	char *base = mtbs_new(tokens[n-1]);
	mtbs_free_split(tokens, n);
	return base;
}

char *file_read_line(FILE *fp) {
	int len = 0, capacity = 2;
	char *str = malloc(sizeof(char) * capacity);
	char c;

	do {
		if(len == capacity) {
			capacity <<= 2;
			str = realloc(str, sizeof(char) * capacity);
		}
		c = fgetc(fp);
		str[len++] = c;
	} while(c != '\n');
	len--;
	str[len] = '\0';
	if(len == 0) {
		free(str);
		return NULL;
	}
	str = realloc(str, sizeof(char) * (len+1));
	return str;
}

void maybe_append_forward_slash(char **path) {
	int len = strlen(*path);
	if((*path)[len-1] == '/')
		return;
	mtbs_concat(2, path, "/");
}

char *ui_read_non_null(char *input) {
	bool valid = false;
	char *str;
	while(!valid) {
		printf("%s", input);
		str = file_read_line(stdin);
		if(str) {
			valid = true;
		}
		else {
			printf("Error! Must not be empty.\n");
		}
	}
	return str;
}

Target *ui_read_target() {
	Target *target = malloc(sizeof(Target));
	// name
	target->name = ui_read_non_null("Enter the name of the target: ");
	// adress
	printf("Enter the address of the target: ");
	target->address = file_read_line(stdin);
	// user
	printf("Enter the user to connect on the target: ");
	target->user = file_read_line(stdin);
	// path
	target->path = ui_read_non_null("Enter the path of the target: ");
	maybe_append_forward_slash(&(target->path));
	return target;
}

Element *ui_read_element() {
	Element *e = malloc(sizeof(Element));
	// name
	e->name = ui_read_non_null("Enter the name of the element: ");
	// source
	e->source = ui_read_non_null("Enter the source path of the element: ");
	maybe_append_forward_slash(&(e->source));
	// destination
	printf("Enter the destination path of the element\n" \
		   "(If empty, will be considered basename(source)): ");
	e->destination = file_read_line(stdin);
	if(!e->destination) {
		e->destination = basename(e->source);
	}
	maybe_append_forward_slash(&(e->destination));
	return e;
}

Profile *ui_read_profile() {
	Profile *p = malloc(sizeof(Profile));
	p->n_elements = 0;
	p->element = NULL;
	// name
	p->name = ui_read_non_null("Enter the name of the profile: ");
	return p;
}

int ui_select_profile(char *prompt, Profile *profile, int n) {
	char opt;
	bool valid = false;

	if(n == 0) {
		printf("There are no profiles to choose\n");
		return -1;
	}

	while(!valid) {
		printf("%s", prompt);
		for(int i = 0; i < n; i++) {
			printf("%d: %s\n", i+1, profile[i].name);
		}
		opt = fgetc(stdin);
		opt = atoi(&opt);
		clear_stdin();
		if(opt > 0 && opt <= n)
			valid = true;
		else
			printf("Invalid element\n");
	}
	return opt-1;
}

int ui_select_element(char *prompt, Element *element, int n) {
	char opt;
	bool valid = false;

	if(n == 0) {
		printf("There are no elements to choose\n");
		return -1;
	}

	while(!valid) {
		printf("%s", prompt);
		for(int i = 0; i < n; i++) {
			printf("%d: %s\n", i+1, element[i].name);
		}
		opt = fgetc(stdin);
		opt = atoi(&opt);
		clear_stdin();
		if(opt > 0 && opt <= n)
			valid = true;
		else
			printf("Invalid element\n");
	}
	return opt-1;
}

int ui_select_target(char *prompt, Target *target, int n) {
	char opt;
	bool valid = false;

	if(n == 0) {
		printf("There are no targets to choose\n");
		return -1;
	}

	while(!valid) {
		printf("%s", prompt);
		for(int i = 0; i < n; i++) {
			printf("%d: %s\n", i+1, target[i].name);
		}
		opt = fgetc(stdin);
		opt = atoi(&opt);
		clear_stdin();
		if(opt > 0 && opt <= n)
			valid = true;
		else
			printf("Invalid target\n");
	}
	return opt-1;
}
