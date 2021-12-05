#include <string.h>
#include "custom_nuklear.h"
#include "gui/input.h"

void erase_input(char *str, int beg, int end) {
	for(int i = beg; i < end; i++) {
		str[i] = '\0';
	}
}

void custom_nk_edit_string(struct nk_context *ctx, char *str, int max) {
	int original_len = strlen(str);
	int len = original_len;

	nk_layout_row_dynamic(ctx, 30, 1);
	nk_edit_string(ctx, NK_EDIT_FIELD,
				   str, &len, max, &nk_filter_default);
  
	if(len < original_len) {
		erase_input(str, len, original_len);
	}
}

void draw_input(struct nk_context *ctx, char *title, char *input, int max) {
	int title_len = strlen(title);
	nk_layout_row_dynamic(ctx, 30, 1);
	nk_text(ctx, title, title_len, NK_TEXT_LEFT);
	custom_nk_edit_string(ctx, input, max);
}
