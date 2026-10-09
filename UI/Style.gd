extends RefCounted
## Estilo visual compartilhado: caixas retas com borda creme, clima de
## portátil clássico (sem cantos arredondados, sem gradientes).

const BG := Color("182030")
const BG_LIGHT := Color("2c4060")
const BORDER := Color("f0e6c8")
const TEXT := Color("f0e6c8")
const ACCENT := Color("e8b83c")
const DARK_TEXT := Color("182030")


static func box(bg: Color = BG, border: Color = BORDER, width: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_content_margin_all(10)
	return sb


static func panel(rect: Rect2) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", box())
	return p


static func label(text: String, size: int = 22, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func outlined(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)


static func style_button(b: Button) -> void:
	b.add_theme_stylebox_override("normal", box(BG_LIGHT))
	b.add_theme_stylebox_override("hover", box(BG_LIGHT, ACCENT))
	b.add_theme_stylebox_override("pressed", box(ACCENT, BORDER))
	b.add_theme_stylebox_override("focus", box(ACCENT, BORDER))
	b.add_theme_stylebox_override("disabled", box(BG, BG_LIGHT))
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", TEXT)
	b.add_theme_color_override("font_focus_color", DARK_TEXT)
	b.add_theme_color_override("font_pressed_color", DARK_TEXT)
	b.add_theme_color_override("font_disabled_color", Color("6a7890"))
	b.add_theme_font_size_override("font_size", 24)
