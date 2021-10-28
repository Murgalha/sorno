#include <string.h>
#include <stdlib.h>
#include "gui.h"

// Nuklear tab from https://github.com/vurtun/nuklear/issues/828
int nk_tab (struct nk_context *ctx, const char *title, int active) {
	const struct nk_user_font *f = ctx->style.font;
	float text_width = f->width(f->userdata, f->height, title, nk_strlen(title));
	float widget_width = text_width + 3 * ctx->style.button.padding.x;
	nk_layout_row_push(ctx, widget_width);
	struct nk_style_item c = ctx->style.button.normal;
	if (active) {ctx->style.button.normal = ctx->style.button.active;}
	int r = nk_button_label (ctx, title);
	ctx->style.button.normal = c;
	return r;
}

GUIData *gui_data_init(sqlite3 *db) {
	GUIData *data = malloc(sizeof(GUIData));
	data->profile_idx = data->target_idx = data->profile_idx = 0;

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

	data->layout = malloc(sizeof(Layout));
	data->layout->tab = SYNC;
	data->layout->edit_mode = false;
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

	free(gui_data->layout);
	free(gui_data);
}

void gui_draw_tab_layout(struct nk_context *ctx, GUIData *gui_data) {
	struct nk_vec2 size;
	int *idx;
	size.x = size.y = 200;

	// TODO: Make static layout and make stuff prettier
	switch(gui_data->layout->tab) {
	case SYNC: // SYNC
		nk_layout_row_dynamic(ctx, 30, gui_data->n_profiles);
		for(int i = 0; i < gui_data->n_profiles; i++) {
			if (nk_option_label(ctx, gui_data->profile[i].name, gui_data->profile_idx == i))
				gui_data->profile_idx = i;
		}
		nk_layout_row_dynamic(ctx, 30, gui_data->n_targets);
		for(int i = 0; i < gui_data->n_targets; i++) {
			if (nk_option_label(ctx, gui_data->target[i].name, gui_data->target_idx == i))
				gui_data->target_idx = i;
		}
		nk_layout_row_dynamic(ctx, 30, 1);
		if (nk_button_label(ctx, "Sync")) {
			// TODO: Sync data
		}

		break;
	case PROFILES: // PROFILES
		idx = &(gui_data->profile_idx);

		nk_combobox(ctx, (const char **)gui_data->profile_names, gui_data->n_profiles, idx, 30, size);
		for(int k = 0; k < gui_data->profile[*idx].n_elements; k++) {
			if (nk_tree_push(ctx, NK_TREE_TAB, gui_data->element[k].name, NK_MINIMIZED)) {
				//nk_layout_row_dynamic(ctx, 30, 1);
				nk_layout_row_dynamic(ctx, 30, 2);
				nk_text(ctx, "Source", 6, NK_TEXT_LEFT);
				nk_text(ctx, gui_data->element[k].source, strlen(gui_data->element[k].source), NK_TEXT_LEFT);
				nk_layout_row_dynamic(ctx, 30, 2);
				nk_text(ctx, "Destination", 11, NK_TEXT_LEFT);
				nk_text(ctx, gui_data->element[k].destination, strlen(gui_data->element[k].destination), NK_TEXT_LEFT);
				nk_tree_pop(ctx);
			}
		}

		break;
	case TARGETS: // TARGETS
		idx = &(gui_data->target_idx);

		nk_combobox(ctx, (const char **)gui_data->target_names, gui_data->n_targets, idx, 30, size);
		nk_layout_row_dynamic(ctx, 30, 2);
		nk_text(ctx, "Name", 4, NK_TEXT_LEFT);
		nk_text(ctx, gui_data->target[*idx].name, strlen(gui_data->target[*idx].name), NK_TEXT_LEFT);
		nk_layout_row_dynamic(ctx, 30, 2);
		nk_text(ctx, "Path", 4, NK_TEXT_LEFT);
		nk_text(ctx, gui_data->target[*idx].path, strlen(gui_data->target[*idx].path), NK_TEXT_LEFT);
		nk_layout_row_dynamic(ctx, 30, 2);
		nk_text(ctx, "Address", 7, NK_TEXT_LEFT);
		nk_text(ctx, gui_data->target[*idx].address, strlen(gui_data->target[*idx].address), NK_TEXT_LEFT);
		nk_layout_row_dynamic(ctx, 30, 2);
		nk_text(ctx, "User", 4, NK_TEXT_LEFT);
		nk_text(ctx, gui_data->target[*idx].user, strlen(gui_data->target[*idx].user), NK_TEXT_LEFT);
		break;
	case ELEMENTS: // ELEMENTS
		idx = &(gui_data->element_idx);

		nk_combobox(ctx, (const char **)gui_data->element_names, gui_data->n_elements, idx, 30, size);
		nk_layout_row_dynamic(ctx, 30, 2);
		nk_text(ctx, "Name", 4, NK_TEXT_LEFT);
		nk_text(ctx, gui_data->element[*idx].name, strlen(gui_data->element[*idx].name), NK_TEXT_LEFT);
		nk_layout_row_dynamic(ctx, 30, 2);
		nk_text(ctx, "Source", 6, NK_TEXT_LEFT);
		nk_text(ctx, gui_data->element[*idx].source, strlen(gui_data->element[*idx].source), NK_TEXT_LEFT);
		nk_layout_row_dynamic(ctx, 30, 2);
		nk_text(ctx, "Destination", 11, NK_TEXT_LEFT);
		nk_text(ctx, gui_data->element[*idx].destination, strlen(gui_data->element[*idx].destination), NK_TEXT_LEFT);
		break;
	default:
		break;
	}
}
