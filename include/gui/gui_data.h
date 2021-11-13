#ifndef _GUI_GUI_DATA_H_
#define _GUI_GUI_DATA_H_

#include <sqlite3.h>
#include <stdbool.h>
#include "data.h"
#include "custom_nuklear.h"

typedef enum {
	ELEMENT,
	TARGET,
	SYNC,
	PROFILE
} Layout;

typedef enum {
	CREATE,
	EDIT
} Action;

typedef enum {
	CLOSED,
	OPEN
} Status;

typedef struct {
	int options;
	Status status;
	char *title;
	Layout layout;
	Action action;
	void (*callback)(struct nk_context *, void *);
	struct nk_rect rect;
} GUIWindow;

typedef struct {
	sqlite3 *db;
	int selected_profile, selected_target, selected_element;
	GUIWindow *main_window;
	GUIWindow *add_window;
} GUIMetadata;

typedef struct {
	int max_size;
	char *name, *address, *user, *source, *destination, *path;
} GUIInput;

typedef struct {
	int n_targets, n_elements, n_profiles;
	Target *target;
	Element *element;
	Profile *profile;
	char **target_names, **profile_names, **element_names;
	GUIMetadata *metadata;
	GUIInput *inputs;
} GUIData;

GUIData *gui_data_init(sqlite3 *);
void gui_data_destroy(GUIData *);
void gui_input_zero_all(GUIInput *);
void gui_data_add_element_to_db(GUIData *, Element);
void gui_data_add_target_to_db(GUIData *, Target);
void gui_data_add_profile_to_db(GUIData *, Profile);
void gui_input_set_input(GUIData *);

#endif
