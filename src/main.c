#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include "window.h"
#define NK_INCLUDE_FIXED_TYPES
#define NK_INCLUDE_STANDARD_IO
#define NK_INCLUDE_STANDARD_VARARGS
#define NK_INCLUDE_DEFAULT_ALLOCATOR
#define NK_INCLUDE_VERTEX_BUFFER_OUTPUT
#define NK_INCLUDE_FONT_BAKING
#define NK_INCLUDE_DEFAULT_FONT
#define NK_KEYSTATE_BASED_INPUT
#define NK_IMPLEMENTATION
#define NK_GLFW_GL3_IMPLEMENTATION
#include "nuklear.h"
#include "nuklear_glfw_gl3.h"
#undef NK_IMPLEMENTATION
#undef NK_GLFW_GL3_IMPLEMENTATION
#include "db.h"
#include "gui.h"

#define MAX_VERTEX_BUFFER 512 * 1024
#define MAX_ELEMENT_BUFFER 128 * 1024

int main(int argc, char *argv[]) {
	struct nk_context *ctx;
    struct nk_glfw *glfw = malloc(sizeof(struct nk_glfw));
    struct nk_colorf bg;
	GLFWwindow *window = window_init();
	sqlite3 *db = db_open();

	GUIData *gui_data = gui_data_init(db);

    ctx = nk_glfw3_init(glfw, window, NK_GLFW3_INSTALL_CALLBACKS);
	// Load default fonts
    struct nk_font_atlas *atlas;
    nk_glfw3_font_stash_begin(glfw, &atlas);
    nk_glfw3_font_stash_end(glfw);

    bg.r = 0.10f, bg.g = 0.18f, bg.b = 0.24f, bg.a = 1.0f;
    while (!glfwWindowShouldClose(window)) {
        processInput(window);
        nk_glfw3_new_frame(glfw);

        glClearColor(0.15f, 0.15f, 0.21f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        if (nk_begin(ctx, "Sorno", nk_rect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT),
					 NK_WINDOW_BORDER)) {

			nk_style_push_vec2(ctx, &ctx->style.window.spacing, nk_vec2(0,0));
			nk_style_push_float(ctx, &ctx->style.button.rounding, 0);
			nk_layout_row_begin(ctx, NK_STATIC, 30, 4);
			// Managing tab behavior
			if (nk_tab (ctx, "Sync", gui_data->layout->tab == SYNC)) {
				gui_data->layout->tab = SYNC;
			}
			if (nk_tab (ctx, "Profiles", gui_data->layout->tab == PROFILES)) {
				gui_data->layout->tab = PROFILES;
			}
			if (nk_tab (ctx, "Targets", gui_data->layout->tab == TARGETS)) {
				gui_data->layout->tab = TARGETS;
			}
			if (nk_tab (ctx, "Elements", gui_data->layout->tab == ELEMENTS)) {
				gui_data->layout->tab = ELEMENTS;
			}
			nk_style_pop_float(ctx);
			nk_style_pop_vec2(ctx);

			gui_draw_tab_layout(ctx, gui_data);
        }
        nk_end(ctx);

        nk_glfw3_render(glfw, NK_ANTI_ALIASING_ON, MAX_VERTEX_BUFFER, MAX_ELEMENT_BUFFER);
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

	gui_data_destroy(gui_data);
	db_close(db);
    nk_glfw3_shutdown(glfw);
	glfwTerminate();
    return 0;
}
