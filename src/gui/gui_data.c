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
	window->action = CREATE;
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

	data->target = db_select_all_targets(db, &(data->n_targets));
	data->profile = db_select_all_profiles(db, &(data->n_profiles));
	data->element = db_select_all_elements(db, &(data->n_elements));

	// Initializing profile names
	data->profile_names = malloc(sizeof(char *) * data->n_profiles);
	for(int k = 0; k < data->n_profiles; k++) {
		data->profile_names[k] = data->profile[k].name;
	}

	// Initializing target names
	data->target_names = malloc(sizeof(char *) * data->n_targets);
	for(int k = 0; k < data->n_targets; k++) {
		data->target_names[k] = data->target[k].name;
	}

	// Initializing element names
	data->element_names = malloc(sizeof(char *) * data->n_elements);
	for(int k = 0; k < data->n_elements; k++) {
		data->element_names[k] = data->element[k].name;
	}

	data->metadata = gui_metadata_init(db);
	data->inputs = gui_input_init(200);
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

void gui_data_add_element_to_db(GUIData *gui_data, Element element) {
	db_insert_element(gui_data->metadata->db, element);

	gui_data->element = realloc(gui_data->element, sizeof(Element) * (gui_data->n_elements+1));

	gui_data->element_names = realloc(gui_data->element_names, sizeof(char *) * (gui_data->n_elements+1));

	gui_data->element[gui_data->n_elements] = element;
	gui_data->element_names[gui_data->n_elements] = element.name;
	(gui_data->n_elements)++;
}

void gui_data_add_target_to_db(GUIData *gui_data, Target target) {
	db_insert_target(gui_data->metadata->db, target);

	gui_data->target = realloc(gui_data->target, sizeof(Target) * (gui_data->n_targets+1));
	gui_data->target_names = realloc(gui_data->target_names, sizeof(char *) * (gui_data->n_targets+1));
	gui_data->target[gui_data->n_targets] = target;
	gui_data->target_names[gui_data->n_targets] = target.name;
	(gui_data->n_targets)++;
}

void gui_data_add_profile_to_db(GUIData *gui_data, Profile profile) {
	db_insert_profile(gui_data->metadata->db, profile);

	gui_data->profile = realloc(gui_data->profile, sizeof(Profile) * (gui_data->n_profiles+1));
	gui_data->profile_names = realloc(gui_data->profile_names, sizeof(char *) * (gui_data->n_profiles+1));

	gui_data->profile[gui_data->n_profiles] = profile;
	gui_data->profile_names[gui_data->n_profiles] = profile.name;
	(gui_data->n_profiles)++;
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
		break;
	case TARGET:
		selected = gui_data->metadata->selected_target;
		Target t = gui_data->target[selected];
		memcpy(gui_data->inputs->name, t.name, strlen(t.name));
		memcpy(gui_data->inputs->user, t.user, strlen(t.user));
		memcpy(gui_data->inputs->address, t.address, strlen(t.address));
		memcpy(gui_data->inputs->path, t.path, strlen(t.path));
		break;
	case PROFILE:
		selected = gui_data->metadata->selected_profile;
		Profile p = gui_data->profile[selected];
		memcpy(gui_data->inputs->name, p.name, strlen(p.name));
		break;
	default:
		break;
 	}
}
