#ifndef _GUI_H_
#define _GUI_H_

#include <stdbool.h>
#include "db.h"

#define NK_INCLUDE_FIXED_TYPES
#define NK_INCLUDE_STANDARD_IO
#define NK_INCLUDE_STANDARD_VARARGS
#define NK_INCLUDE_DEFAULT_ALLOCATOR
#define NK_INCLUDE_VERTEX_BUFFER_OUTPUT
#define NK_INCLUDE_FONT_BAKING
#define NK_INCLUDE_DEFAULT_FONT
#define NK_KEYSTATE_BASED_INPUT
#include "nuklear.h"
#include "nuklear_glfw_gl3.h"

enum {
	ELEMENTS,
	TARGETS,
	SYNC,
	PROFILES
};

typedef struct {
	int tab;
	bool edit_mode;
} Layout;

typedef struct {
	int n_targets, n_elements, n_profiles;
	Target *target;
	Element *element;
	Profile *profile;
	int profile_idx, target_idx, element_idx;
	char **target_names, **profile_names, **element_names;
	Layout *layout;
} GUIData;

void gui_draw_tab_layout(struct nk_context *, GUIData *);
GUIData *gui_data_init(sqlite3 *);
void gui_data_destroy(GUIData *);
int nk_tab (struct nk_context *, const char *, int);

#endif
