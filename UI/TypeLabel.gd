extends Label
## Label que "digita" o texto letra por letra (efeito de caixa de diálogo
## clássica). Evolução do DescriptionBox da base original.

const CHARS_PER_SECOND := 48.0

var typing: bool = false
var _progress: float = 0.0


func _ready() -> void:
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_theme_color_override("font_color", Color("f0e6c8"))


func start(t: String) -> void:
	text = t
	_progress = 0.0
	visible_characters = 0
	typing = t.length() > 0


func skip() -> void:
	if typing:
		typing = false
		visible_characters = -1


func _process(delta: float) -> void:
	if not typing:
		return
	_progress += delta * CHARS_PER_SECOND
	visible_characters = int(_progress)
	if visible_characters >= text.length():
		typing = false
		visible_characters = -1
