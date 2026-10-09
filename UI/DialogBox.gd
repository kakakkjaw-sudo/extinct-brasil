extends CanvasLayer
## Caixa de diálogo com texto digitado. Uso: await dialog.say(["linha 1", ...], "Nome")

const Style := preload("res://UI/Style.gd")
const TypeLabelScript := preload("res://UI/TypeLabel.gd")

var panel: Panel
var name_panel: Panel
var name_label: Label
var text_label            # TypeLabel
var arrow: Label


func _ready() -> void:
	layer = 5
	visible = false
	panel = Style.panel(Rect2(30, 450, 900, 170))
	add_child(panel)
	text_label = TypeLabelScript.new()
	text_label.position = Vector2(22, 18)
	text_label.size = Vector2(856, 126)
	text_label.add_theme_font_size_override("font_size", 28)
	panel.add_child(text_label)
	arrow = Style.label("v", 26, Style.ACCENT)
	arrow.position = Vector2(860, 128)
	panel.add_child(arrow)
	name_panel = Style.panel(Rect2(30, 402, 250, 54))
	add_child(name_panel)
	name_label = Style.label("", 26, Style.ACCENT)
	name_label.position = Vector2(16, 6)
	name_panel.add_child(name_label)
	# toque/clique em qualquer lugar da tela avança o texto (celular)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tap := Control.new()
	tap.size = Vector2(960, 640)
	tap.mouse_filter = Control.MOUSE_FILTER_STOP
	tap.gui_input.connect(_on_tap)
	add_child(tap)


func say(lines: Array, speaker: String = "") -> void:
	name_label.text = speaker
	name_panel.visible = speaker != ""
	visible = true
	for line in lines:
		text_label.start(str(line))
		arrow.visible = false
		while text_label.typing:
			await get_tree().process_frame
			if Input.is_action_just_pressed("interact"):
				text_label.skip()
		arrow.visible = true
		while true:
			await get_tree().process_frame
			if Input.is_action_just_pressed("interact"):
				break
	visible = false


func _on_tap(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		Game.tap_interact()
