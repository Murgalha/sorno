#include "custom_nuklear.h"

// Nuklear tab from https://github.com/vurtun/nuklear/issues/828
int nk_tab(struct nk_context *ctx, const char *title, int active) {
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
