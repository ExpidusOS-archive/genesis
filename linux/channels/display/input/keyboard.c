#include "keyboard.h"
#include <wlr/interfaces/wlr_keyboard.h>

static const struct wlr_keyboard_impl keyboard_impl = {
	.name = "keyboard",
};

void keyboard_init(struct wlr_keyboard* keyboard) {
  wlr_keyboard_init(keyboard, &keyboard_impl, "keyboard");
}
