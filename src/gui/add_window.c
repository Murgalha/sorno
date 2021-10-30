#include <stdio.h>
#include <stdlib.h>
#include "gui/gui_data.h"
#include "gui/add_window.h"
#include "gui/input.h"
#include "db/queries.h"
#include "mtb_str.h"

void empty_callback(struct nk_context *ctx, void *pointer) {}

void gui_draw_add_window_save_button(struct nk_context *ctx, GUIData *gui_data) {
	GUIWindow *add_window = gui_data->metadata->add_window;

	if(nk_button_label(ctx, "Save")) {
		Target target;
		Element element;
		Profile profile;
		GUIInput *inputs = gui_data->inputs;
		sqlite3 *db = gui_data->metadata->db;

		add_window->status = CLOSED;
		switch(add_window->layout) {
		case TARGET:
			target.name = inputs->name;
			target.user = inputs->user;
			target.address = inputs->address;
			target.path = inputs->path;
			break;
		case ELEMENT:
			element.name = inputs->name;
			element.source = inputs->source;
			element.destination = inputs->destination;
			break;
		case PROFILE:
			profile.name = inputs->name;
			break;
		default:
			break;
		}
	}
}

void gui_draw_add_window_target(struct nk_context *ctx, void *data) {
	GUIData *gui_data = (GUIData *)data;
	int max_size = gui_data->inputs->max_size;

	draw_input(ctx, "Name:", gui_data->inputs->name, max_size);
	draw_input(ctx, "Path:", gui_data->inputs->path, max_size);
	draw_input(ctx, "Address:", gui_data->inputs->address, max_size);
	draw_input(ctx, "User:", gui_data->inputs->user, max_size);
	gui_draw_add_window_save_button(ctx, gui_data);
}

void gui_draw_add_window_profile(struct nk_context *ctx, void *data) {
	GUIData *gui_data = (GUIData *)data;
	int max_size = gui_data->inputs->max_size;

	draw_input(ctx, "Name:", gui_data->inputs->name, max_size);
	gui_draw_add_window_save_button(ctx, gui_data);
}

void gui_draw_add_window_element(struct nk_context *ctx, void *data) {
	GUIData *gui_data = (GUIData *)data;
	int max_size = gui_data->inputs->max_size;

	draw_input(ctx, "Name:", gui_data->inputs->name, max_size);
	draw_input(ctx, "Source path:", gui_data->inputs->source, max_size);
	draw_input(ctx, "Destination path:", gui_data->inputs->destination, max_size);
	gui_draw_add_window_save_button(ctx, gui_data);
}


void gui_set_add_window_layout(struct nk_context *ctx, GUIData *gui_data, Layout layout) {
	GUIWindow *window = gui_data->metadata->add_window;
	switch(layout) {
	case TARGET:
		free(window->title);
		window->title = mtbs_new("Add Target");
		window->callback = &gui_draw_add_window_target;
		break;
	case PROFILE:
		free(window->title);
		window->title = mtbs_new("Add Profile");
		window->callback = &gui_draw_add_window_profile;
		break;
	case ELEMENT:
		free(window->title);
		window->title = mtbs_new("Add Elements");
		window->callback = &gui_draw_add_window_element;
		break;
	default:
		window->callback = &empty_callback;
		break;
	}
	int max_size = gui_data->inputs->max_size;

	gui_input_zero_all(gui_data->inputs);
}

void gui_draw_add_button(struct nk_context *ctx, GUIData *gui_data, Layout layout, char *label) {
	GUIWindow *add_window = gui_data->metadata->add_window;

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
		nk_button_label(ctx, label);
		ctx->style.button = button;
	}
	else {
		if(nk_button_label(ctx, label)) {
			gui_set_add_window_layout(ctx, gui_data, layout);
			gui_data->metadata->add_window->status = OPEN;
			gui_data->metadata->add_window->layout = layout;
		}
	}
}

void gui_draw_add_window(struct nk_context *ctx, GUIData *gui_data) {
	GUIWindow *window = gui_data->metadata->add_window;

	if(window->status == OPEN) {
		nk_window_set_focus(ctx, window->title);
		if (nk_begin(ctx, window->title, window->rect, window->options)) {
			struct nk_vec2 position = nk_window_get_position(ctx);
			window->rect.x = position.x;
			window->rect.y = position.y;
			nk_style_push_vec2(ctx, &ctx->style.window.spacing, nk_vec2(0,0));
			nk_style_push_float(ctx, &ctx->style.button.rounding, 0);

			window->callback(ctx, gui_data);

			nk_style_pop_float(ctx);
			nk_style_pop_vec2(ctx);
		}
		else {
			window->status = CLOSED;
		}
		nk_end(ctx);
	}
}
