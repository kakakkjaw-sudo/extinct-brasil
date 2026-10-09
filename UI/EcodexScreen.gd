extends CanvasLayer
## Tela da ECODEX: lista de espécies à esquerda, ficha científica à direita.
## Espécies não descobertas aparecem como ???.

signal closed

const Style := preload("res://UI/Style.gd")

var header: Label
var list: ItemList
var pic: TextureRect
var title: Label
var sci: Label
var details: RichTextLabel
var _ignore_frame: int = -1


func _ready() -> void:
	layer = 15
	visible = false

	var bg := ColorRect.new()
	bg.color = Color("0c1018")
	bg.size = Vector2(960, 640)
	add_child(bg)

	var top := Style.panel(Rect2(20, 16, 920, 64))
	add_child(top)
	header = Style.label("", 24)
	header.position = Vector2(16, 14)
	top.add_child(header)

	list = ItemList.new()
	list.position = Vector2(20, 96)
	list.size = Vector2(340, 480)
	list.add_theme_font_size_override("font_size", 22)
	list.add_theme_stylebox_override("panel", Style.box())
	list.add_theme_stylebox_override("focus", Style.box(Style.BG, Style.ACCENT))
	list.add_theme_stylebox_override("selected", Style.box(Style.ACCENT, Style.ACCENT, 0))
	list.add_theme_stylebox_override("selected_focus", Style.box(Style.ACCENT, Style.ACCENT, 0))
	list.add_theme_color_override("font_color", Style.TEXT)
	list.add_theme_color_override("font_selected_color", Style.DARK_TEXT)
	list.add_theme_color_override("font_hovered_color", Style.TEXT)
	list.item_selected.connect(_show_details)
	add_child(list)

	var right := Style.panel(Rect2(380, 96, 560, 480))
	add_child(right)
	pic = TextureRect.new()
	pic.position = Vector2(16, 16)
	pic.size = Vector2(128, 128)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	right.add_child(pic)
	title = Style.label("", 28, Style.ACCENT)
	title.position = Vector2(160, 30)
	title.size = Vector2(380, 40)
	right.add_child(title)
	sci = Style.label("", 20)
	sci.position = Vector2(160, 76)
	sci.size = Vector2(380, 40)
	right.add_child(sci)
	details = RichTextLabel.new()
	details.bbcode_enabled = true
	details.position = Vector2(16, 156)
	details.size = Vector2(528, 312)
	for f in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]:
		details.add_theme_font_size_override(f, 19)
	details.add_theme_color_override("default_color", Style.TEXT)
	right.add_child(details)

	var foot := Style.label(Game.dica("Setas: escolher    X ou C: fechar", "Toque numa espécie para ver a ficha"), 18)
	foot.position = Vector2(24, 596)
	add_child(foot)

	# botão FECHAR (celular e mouse)
	var close_btn := Button.new()
	close_btn.text = "FECHAR"
	close_btn.position = Vector2(780, 22)
	close_btn.size = Vector2(150, 52)
	close_btn.focus_mode = Control.FOCUS_NONE
	Style.style_button(close_btn)
	close_btn.pressed.connect(_close)
	add_child(close_btn)


func open() -> void:
	_ignore_frame = Engine.get_process_frames()
	_refresh()
	visible = true
	list.grab_focus()
	await closed


func _process(_delta: float) -> void:
	if not visible or Engine.get_process_frames() == _ignore_frame:
		return
	if Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("ecodex"):
		_close()


func _close() -> void:
	if not visible:
		return
	get_viewport().gui_release_focus()
	visible = false
	closed.emit()


func _refresh() -> void:
	header.text = "ECODEX    Descobertas: %d/%d    Estudadas: %d/%d" % [
		Ecodex.seen_count(), Ecodex.total(), Ecodex.captured_count(), Ecodex.total()]
	list.clear()
	for sp in Ecodex.species:
		var shown := "???"
		if Ecodex.is_seen(str(sp.id)):
			shown = str(sp.nome)
		list.add_item("#%03d  %s" % [int(sp.numero), shown])
	if list.item_count > 0:
		list.select(0)
		_show_details(0)


func _show_details(index: int) -> void:
	var sp: Dictionary = Ecodex.species[index]
	var seen: bool = Ecodex.is_seen(str(sp.id))
	var studied: bool = Ecodex.is_captured(str(sp.id))
	pic.texture = load(str(sp.sprite))
	if not seen:
		pic.modulate = Color.BLACK
		title.text = "#%03d  ???" % int(sp.numero)
		sci.text = "???"
		details.text = "Espécie ainda não descoberta.\n\nExplore as regiões e procure rastros no capim alto."
		return
	pic.modulate = Color.WHITE
	title.text = "#%03d  %s" % [int(sp.numero), str(sp.nome)]
	sci.text = str(sp.cientifico)
	var t := ""
	t += "[color=#e8b83c]Período:[/color] %s\n" % str(sp.periodo)
	t += "[color=#e8b83c]Região:[/color] %s\n" % str(sp.regiao)
	t += "[color=#e8b83c]Habitat:[/color] %s\n" % str(sp.habitat)
	t += "[color=#e8b83c]Alimentação:[/color] %s\n" % str(sp.alimentacao)
	t += "[color=#e8b83c]Tamanho:[/color] %s\n" % str(sp.tamanho)
	t += "[color=#e8b83c]Status:[/color] %s\n\n" % str(sp.status)
	if studied:
		t += "[color=#e8b83c]Curiosidade:[/color] %s\n\n" % str(sp.curiosidade)
		t += "[color=#e8b83c]Informação histórica:[/color] %s" % str(sp.historia)
	else:
		t += "[color=#8890a0]Capture esta espécie com a Temporal Capsule para estudar a Curiosidade e a Informação histórica.[/color]"
	details.text = t
