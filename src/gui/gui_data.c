#include <stdio.h>
#include "custom_nuklear.h"
#include <stdbool.h>
#include <stdlib.h>
#include "gui/gui_data.h"
#include "db.h"
#include "mtb_str.h"
#include "utils.h"

void initial_callback(struct nk_context *ctx, void *pointer) {}

GUIWindow *gui_window_init(char *title, int width, int height, Layout layout, int options) {
	GUIWindow *window = malloc(sizeof(GUIWindow));
	window->options = options;
	window->title = title;
	window->layout = layout;
	window->rect = nk_rect(0, 0, width, height);
	window->status = CLOSED;
	window->callback = &initial_callback;
	window->action = ADD;
	return window;
}

void gui_window_destroy(GUIWindow *window) {
	free(window->title);
	free(window);
}

GUIInput *gui_input_init(int max) {
	GUIInput *inputs = malloc(sizeof(GUIInput));
	inputs->name = calloc(max, sizeof(char));
	inputs->address = calloc(max, sizeof(char));
	inputs->user = calloc(max, sizeof(char));
	inputs->source = calloc(max, sizeof(char));
	inputs->destination = calloc(max, sizeof(char));
	inputs->path = calloc(max, sizeof(char));
	inputs->max_size = max;
	inputs->id = -1;

	return inputs;
}

void gui_input_destroy(GUIInput *inputs) {
	free(inputs->name);
	free(inputs->address);
	free(inputs->user);
	free(inputs->source);
	free(inputs->destination);
	free(inputs->path);
	free(inputs);
}

void gui_input_zero_all(GUIInput *inputs) {
	int max_size = inputs->max_size;
	memset(inputs->name, '\0', max_size);
	memset(inputs->path, '\0', max_size);
	memset(inputs->user, '\0', max_size);
	memset(inputs->source, '\0', max_size);
	memset(inputs->destination, '\0', max_size);
	memset(inputs->address, '\0', max_size);
	memset(inputs->name, '\0', max_size);
	inputs->id = -1;
}

GUIMetadata *gui_metadata_init(sqlite3 *db) {
	GUIMetadata *metadata = malloc(sizeof(GUIMetadata));
	metadata->selected_profile = 0;
	metadata->selected_target = 0;
	metadata->selected_element = 0;
	metadata->db = db;

	int default_options = NK_WINDOW_BORDER |
		NK_WINDOW_MOVABLE;

	metadata->main_window = gui_window_init(mtbs_new("Sorno"),
											SCREEN_WIDTH,
											SCREEN_HEIGHT,
											SYNC,
											default_options);
	metadata->main_window->status = OPEN;
	metadata->add_window = gui_window_init(mtbs_new("Add"),
										   SCREEN_WIDTH/2,
										   SCREEN_HEIGHT/2,
										   TARGET,
										   default_options | NK_WINDOW_CLOSABLE);

	return metadata;
}

void gui_metadata_destroy(GUIMetadata *metadata) {
	gui_window_destroy(metadata->main_window);
	gui_window_destroy(metadata->add_window);
	free(metadata);
}

GUIData *gui_data_init(sqlite3 *db) {
	GUIData *data = calloc(1, sizeof(GUIData));
	data->metadata = gui_metadata_init(db);
	data->inputs = gui_input_init(200);

	gui_data_refresh_elements(data);
	gui_data_refresh_targets(data);
	gui_data_refresh_profiles(data);

	return data;
}

void gui_data_destroy(GUIData *gui_data) {
	for(int i = 0; i < gui_data->n_profiles; i++) {
		profile_free(gui_data->profile + i);
	}
	for(int i = 0; i < gui_data->n_targets; i++) {
		target_free(gui_data->target + i);
	}
	for(int i = 0; i < gui_data->n_elements; i++) {
		element_free(gui_data->element + i);
	}

	gui_metadata_destroy(gui_data->metadata);
	gui_input_destroy(gui_data->inputs);
	free(gui_data);
}

void gui_data_refresh_targets(GUIData *gui_data) {
	free(gui_data->target);
	gui_data->target = db_select_all_targets(gui_data->metadata->db, &(gui_data->n_targets));

	// Initializing target names
	free(gui_data->target_names);
	gui_data->target_names = malloc(sizeof(char *) * gui_data->n_targets);
	for(int k = 0; k < gui_data->n_targets; k++) {
		gui_data->target_names[k] = gui_data->target[k].name;
	}
}

void gui_data_refresh_elements(GUIData *gui_data) {
	free(gui_data->element);
	gui_data->element = db_select_all_elements(gui_data->metadata->db, &(gui_data->n_elements));

	// Initializing element names
	free(gui_data->element_names);
	gui_data->element_names = malloc(sizeof(char *) * gui_data->n_elements);
	for(int k = 0; k < gui_data->n_elements; k++) {
		gui_data->element_names[k] = gui_data->element[k].name;
	}
}

void gui_data_refresh_profiles(GUIData *gui_data) {
	free(gui_data->profile);
	gui_data->profile = db_select_all_profiles(gui_data->metadata->db, &(gui_data->n_profiles));

	// Initializing profile names
	free(gui_data->profile_names);
	gui_data->profile_names = malloc(sizeof(char *) * gui_data->n_profiles);
	for(int k = 0; k < gui_data->n_profiles; k++) {
		gui_data->profile_names[k] = gui_data->profile[k].name;
	}
}

void gui_data_add_element_to_db(GUIData *gui_data, Element element) {
	db_insert_element(gui_data->metadata->db, element);
	gui_data_refresh_elements(gui_data);
}

void gui_data_add_target_to_db(GUIData *gui_data, Target target) {
	db_insert_target(gui_data->metadata->db, target);
	gui_data_refresh_targets(gui_data);
}

void gui_data_add_profile_to_db(GUIData *gui_data, Profile profile) {
	db_insert_profile(gui_data->metadata->db, profile);
	gui_data_refresh_profiles(gui_data);
}

void gui_data_update_element_to_db(GUIData *gui_data, Element element) {
	db_update_element(gui_data->metadata->db, element);
	gui_data_refresh_elements(gui_data);
}

void gui_data_update_target_to_db(GUIData *gui_data, Target target) {
	db_update_target(gui_data->metadata->db, target);
	gui_data_refresh_targets(gui_data);
}

void gui_data_update_profile_to_db(GUIData *gui_data, Profile profile) {
	db_update_profile(gui_data->metadata->db, profile);
	gui_data_refresh_profiles(gui_data);
}


void gui_input_set_input(GUIData *gui_data) {
	Layout layout = gui_data->metadata->add_window->layout;
	int selected = -1;

	switch(layout) {
	case ELEMENT:
		selected = gui_data->metadata->selected_element;
		Element e = gui_data->element[selected];
		memcpy(gui_data->inputs->name, e.name, strlen(e.name));
		memcpy(gui_data->inputs->source, e.source, strlen(e.source));
		memcpy(gui_data->inputs->destination, e.destination, strlen(e.destination));
		gui_data->inputs->id = e.id;
		break;
	case TARGET:
		selected = gui_data->metadata->selected_target;
		Target t = gui_data->target[selected];
		memcpy(gui_data->inputs->name, t.name, strlen(t.name));
		memcpy(gui_data->inputs->user, t.user, strlen(t.user));
		memcpy(gui_data->inputs->address, t.address, strlen(t.address));
		memcpy(gui_data->inputs->path, t.path, strlen(t.path));
		gui_data->inputs->id = t.id;
		break;
	case PROFILE:
		selected = gui_data->metadata->selected_profile;
		Profile p = gui_data->profile[selected];
		memcpy(gui_data->inputs->name, p.name, strlen(p.name));
		gui_data->inputs->id = p.id;
		break;
	default:
		break;
 	}
}
