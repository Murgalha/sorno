#ifndef _GUI_MAIN_WINDOW_H_
#define _GUI_MAIN_WINDOW_H_

void gui_draw_main_window_sync_layout(struct nk_context *, GUIData *);
void gui_draw_main_window_profiles_layout(struct nk_context *, GUIData *);
void gui_draw_main_window_targets_layout(struct nk_context *, GUIData *);
void gui_draw_main_window_elements_layout(struct nk_context *, GUIData *);
void gui_draw_main_window_layout(struct nk_context *, GUIData *);
void gui_set_main_window_layout(struct nk_context *, GUIData *);
void gui_draw_main_window(struct nk_context *, GUIData *);
void gui_draw_all_windows(struct nk_context *, GUIData *);


#endif
