#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <sys/stat.h>
#include <errno.h>
#include "ui.h"
#include "db.h"
#include "sync.h"

void add_profile(sqlite3 *db) {
	Profile *prof;
	prof = ui_read_profile();
	db_insert_profile(db, prof);
	profile_free(prof);
}

void add_element(sqlite3 *db) {
	Element *element;
	element = ui_read_element();
	db_insert_element(db, element);
	element_free(element);
}

void add_target(sqlite3 *db) {
	Target *target;
	target = ui_read_target();
	db_insert_target(db, target);
	target_free(target);
}

void link_element(sqlite3 *db) {
	Profile *profile;
	Element *element;
	int n_profiles, p_idx;
	int n_elements, e_idx;

	element = db_select_unlinked_elements(db, &n_elements);
	profile = db_select_profile_names(db, &n_profiles);

	e_idx = ui_select_element("Select the element to link:\n", element, n_elements);

	if(e_idx == -1)
		return;

	p_idx = ui_select_profile("Select the profile to link to:\n", profile, n_profiles);

	if(p_idx == -1)
		return;

	db_link_element(db, element + e_idx, profile + p_idx);
}

void sync_profile(sqlite3 *db) {
	Profile *profile, *full_profile;
	Target *target;
	int n_profiles, p_idx;
	int n_targets, t_idx;

	profile = db_select_profile_names(db, &n_profiles);
	p_idx = ui_select_profile("Choose the profile to sync:\n", profile, n_profiles);

	if(p_idx == -1)
		return;

	// get profile with elements
	full_profile = db_select_profile(db, (profile + p_idx)->name);

	profile_free(profile);

	target = db_select_targets(db, &n_targets);
	t_idx = ui_select_target("Choose target to sync:\n", target, n_targets);
	sync_profile_to_target(full_profile, target + t_idx);
}

int main(int argc, char *argv[]) {
	bool quit = false;
	char opt;

	sqlite3 *db = db_open();
	db_create_tables(db);

	while(!quit) {
		printf("\n");
		printf("1: Add profile\n");
		printf("2: Add element\n");
		printf("3: Add target\n");
		printf("4: Link element\n");
		printf("5: Sync profile\n");
		printf("6: Quit\n");

		opt = fgetc(stdin);
		clear_stdin();

		switch(opt) {
		case '1':
			add_profile(db);
			break;
		case '2':
			add_element(db);
			break;
		case '3':
			add_target(db);
			break;
		case '4':
			link_element(db);
			break;
		case '5':
			sync_profile(db);
			break;
		case '6':
			quit = true;
			break;
		default:
			printf("Invalid command! Enter a valid one\n");
			break;
		}

	}

	db_close(db);
	return 0;
}
