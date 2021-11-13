#include <string.h>
#include "gui/gui_data.h"
#include "gui/update_window.h"

//
// TODO: Make static layout and make stuff prettier
//

//
// NO DATA LAYOUTS
//
void gui_draw_main_window_no_targets(struct nk_context *ctx, GUIData *gui_data) {
    nk_layout_row_dynamic(ctx, 30, 1);
	nk_label(ctx, "No available Targets", NK_TEXT_CENTERED);
	nk_layout_row_dynamic(ctx, 30, 1);
	gui_draw_update_button(ctx, gui_data, TARGET, CREATE, "Add Target");
}

void gui_draw_main_window_no_profiles(struct nk_context *ctx, GUIData *gui_data) {
    nk_layout_row_dynamic(ctx, 30, 1);
	nk_label(ctx, "No available Profiles", NK_TEXT_CENTERED);
	nk_layout_row_dynamic(ctx, 30, 1);
	gui_draw_update_button(ctx, gui_data, PROFILE, CREATE, "Add Profile");
}

void gui_draw_main_window_no_elements(struct nk_context *ctx, GUIData *gui_data) {
    nk_layout_row_dynamic(ctx, 30, 1);
	nk_label(ctx, "No available Elements", NK_TEXT_CENTERED);
	nk_layout_row_dynamic(ctx, 30, 1);
	gui_draw_update_button(ctx, gui_data, ELEMENT, CREATE, "Add Element");
}

//
// STANDARD LAYOUTS
//
void gui_draw_main_window_sync_layout(struct nk_context *ctx, GUIData *gui_data) {
	int profile_index = gui_data->metadata->selected_profile;
	int target_index = gui_data->metadata->selected_target;

	if(gui_data->n_profiles > 0) {
		nk_layout_row_dynamic(ctx, 30, gui_data->n_profiles);
		for(int i = 0; i < gui_data->n_profiles; i++) {
			if (nk_option_label(ctx, gui_data->profile[i].name, profile_index == i))
				gui_data->metadata->selected_profile = i;
		}
	}
	else {
		nk_layout_row_dynamic(ctx, 30, 3);
		nk_label(ctx, "No available Profiles", NK_TEXT_CENTERED);
		nk_label(ctx, "", NK_TEXT_CENTERED);
		gui_draw_update_button(ctx, gui_data, PROFILE, CREATE, "Add Profile");
	}
	if(gui_data->n_targets) {
		nk_layout_row_dynamic(ctx, 30, gui_data->n_targets);
		for(int i = 0; i < gui_data->n_targets; i++) {
			if (nk_option_label(ctx, gui_data->target[i].name, target_index == i))
				gui_data->metadata->selected_target = i;
		}
	}
	else {
		nk_layout_row_dynamic(ctx, 30, 3);
		nk_label(ctx, "No available Targets", NK_TEXT_CENTERED);
		nk_label(ctx, "", NK_TEXT_CENTERED);
		gui_draw_update_button(ctx, gui_data, TARGET, CREATE, "Add Target");
	}

	nk_layout_row_dynamic(ctx, 30, 1);
	GUIWindow *add_window = gui_data->metadata->add_window;
	char *sync_label = "Sync";

	// If add window is open, the main window buttons become greyed out
	// and unclickable
	if(add_window->status == OPEN) {
		struct nk_style_button button;
		button = ctx->style.button;
		ctx->style.button.normal = nk_style_item_color(nk_rgb(40,40,40));
		ctx->style.button.hover = nk_style_item_color(nk_rgb(40,40,40));
		ctx->style.button.active = nk_style_item_color(nk_rgb(40,40,40));
		ctx->style.button.border_color = nk_rgb(60,60,60);
		ctx->style.button.text_background = nk_rgb(60,60,60);
		ctx->style.button.text_normal = nk_rgb(60,60,60);
		ctx->style.button.text_hover = nk_rgb(60,60,60);
		ctx->style.button.text_active = nk_rgb(60,60,60);
		nk_button_label(ctx, sync_label);
		ctx->style.button = button;
	}
	else {
		if(nk_button_label(ctx, sync_label)) {
			// TODO: Sync data
		}
	}
}

void gui_draw_main_window_profiles_layout(struct nk_context *ctx, GUIData *gui_data) {
	if(gui_data->n_profiles == 0) {
		gui_draw_main_window_no_profiles(ctx, gui_data);
		return;
	}
	struct nk_vec2 size;
	size.x = size.y = 200;
	int *idx = &(gui_data->metadata->selected_profile);

	nk_combobox(ctx, (const char **)gui_data->profile_names, gui_data->n_profiles, idx, 30, size);
	gui_draw_update_button(ctx, gui_data, PROFILE, EDIT, "Edit profile");
	for(int k = 0; k < gui_data->profile[*idx].n_elements; k++) {
		Element element;
		for(int i = 0; i < gui_data->n_elements; i++) {
			if(!strcmp(gui_data->profile[*idx].element_names[k], gui_data->element[i].name)) {
				element = gui_data->element[i];
			}
		}

		if (nk_tree_push(ctx, NK_TREE_TAB, element.name, NK_MINIMIZED)) {
			nk_layout_row_dynamic(ctx, 30, 2);
			nk_text(ctx, "Source", 6, NK_TEXT_LEFT);
			nk_text(ctx, element.source, strlen(element.source), NK_TEXT_LEFT);
			nk_layout_row_dynamic(ctx, 30, 2);
			nk_text(ctx, "Destination", 11, NK_TEXT_LEFT);
			nk_text(ctx, element.destination, strlen(element.destination), NK_TEXT_LEFT);
			nk_tree_pop(ctx);
		}
	}
}

void gui_draw_main_window_targets_layout(struct nk_context *ctx, GUIData *gui_data) {
	if(gui_data->n_targets == 0) {
		gui_draw_main_window_no_targets(ctx, gui_data);
		return;
	}
	struct nk_vec2 size;
	size.x = size.y = 200;
	int *idx = &(gui_data->metadata->selected_target);

	nk_combobox(ctx, (const char **)gui_data->target_names, gui_data->n_targets, idx, 30, size);
	gui_draw_update_button(ctx, gui_data, TARGET, EDIT, "Edit target");
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
}

void gui_draw_main_window_elements_layout(struct nk_context *ctx, GUIData *gui_data) {
	if(gui_data->n_elements == 0) {
		gui_draw_main_window_no_elements(ctx, gui_data);
		return;
	}
	struct nk_vec2 size;
	size.x = size.y = 200;
	int *idx = &(gui_data->metadata->selected_element);

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
}

void gui_draw_main_window_layout(struct nk_context *ctx, GUIData *gui_data) {
	switch(gui_data->metadata->main_window->layout) {
	case SYNC:
		gui_draw_main_window_sync_layout(ctx, gui_data);
		break;
	case PROFILE:
		gui_draw_main_window_profiles_layout(ctx, gui_data);
		break;
	case TARGET:
		gui_draw_main_window_targets_layout(ctx, gui_data);
		break;
	case ELEMENT:
		gui_draw_main_window_elements_layout(ctx, gui_data);
		break;
	default:
		break;
	}
}

void gui_set_main_window_layout(struct nk_context *ctx, GUIData *gui_data) {
	GUIWindow *window = gui_data->metadata->main_window;

	nk_style_push_vec2(ctx, &ctx->style.window.spacing, nk_vec2(0,0));
	nk_style_push_float(ctx, &ctx->style.button.rounding, 0);
	nk_layout_row_begin(ctx, NK_STATIC, 30, 4);
	if (nk_tab (ctx, "Sync", window->layout == SYNC)) {
		window->layout = SYNC;
	}
	if (nk_tab (ctx, "Profiles", window->layout == PROFILE)) {
		window->layout = PROFILE;
	}
	if (nk_tab (ctx, "Targets", window->layout == TARGET)) {
		window->layout = TARGET;
	}
	if (nk_tab (ctx, "Elements", window->layout == ELEMENT)) {
		window->layout = ELEMENT;
	}
	nk_style_pop_float(ctx);
	nk_style_pop_vec2(ctx);
}

void gui_draw_main_window(struct nk_context *ctx, GUIData *gui_data) {
	GUIWindow *window = gui_data->metadata->main_window;

	if (nk_begin(ctx, window->title, window->rect, window->options)) {

		nk_style_push_vec2(ctx, &ctx->style.window.spacing, nk_vec2(0,0));
		nk_style_push_float(ctx, &ctx->style.button.rounding, 0);

		gui_set_main_window_layout(ctx, gui_data);

		nk_style_pop_float(ctx);
		nk_style_pop_vec2(ctx);

		gui_draw_main_window_layout(ctx, gui_data);
	}
	nk_end(ctx);
}

void gui_draw_all_windows(struct nk_context *ctx, GUIData *gui_data) {
	gui_draw_main_window(ctx, gui_data);
	gui_draw_update_window(ctx, gui_data);
}
