#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include "window.h"
#define NK_IMPLEMENTATION
#define NK_GLFW_GL3_IMPLEMENTATION
#include "custom_nuklear.h"
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

        gui_draw_all_windows(ctx, gui_data);

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
