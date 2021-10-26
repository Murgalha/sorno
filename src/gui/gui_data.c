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
	GUIData *data = malloc(sizeof(GUIData));

	data->target = db_select_targets(db, &(data->n_targets));
	data->profile = db_select_profiles(db, &(data->n_profiles));
	data->element = db_select_elements(db, &(data->n_elements));

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
	free(gui_data);
}
