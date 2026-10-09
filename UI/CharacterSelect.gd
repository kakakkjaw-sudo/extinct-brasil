extends Node2D
## Tela "ESCOLHA SEU CAÇADOR": 6 vagas (3 x 2) lidas de Data/equipe.json.
## Para trocar a imagem de um caçador, substitua Assets/Portraits/<id>.png
## (qualquer tamanho; a imagem é ajustada ao quadro).

const Style := preload("res://UI/Style.gd")

const CARD_W := 290
const CARD_H := 206
const GAP_X := 15
const GAP_Y := 14
const GRID_X := 30
const GRID_Y := 132
const COLS := 3
const WORLD_SCENE := "res://World/World.tscn"
const TITLE_SCENE := "res://UI/TitleScreen.tscn"

const CREAM := Color("f6e2b8")
const BROWN := Color("8c5a2a")
const DARK := Color("2a1a10")
const GREEN := Color("a8c890")
const SELECTED := Color("e0501a")

var cards: Array = []           # cada item: {"panel": Panel, "ch": Dictionary}
var index: int = 0
var confirming: bool = false
var locked: bool = true
var subtitle: Label
var start_label: Label
var fade: ColorRect


func _ready() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://Assets/UI/title.png")
	bg.size = Vector2(960, 640)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.modulate = Color(0.55, 0.55, 0.6)
	add_child(bg)

	# barra de título
	var title_panel := Panel.new()
	title_panel.position = Vector2(30, 14)
	title_panel.size = Vector2(900, 64)
	title_panel.add_theme_stylebox_override("panel", Style.box(CREAM, BROWN, 4))
	add_child(title_panel)
	var title := Style.label("ESCOLHA SEU CAÇADOR", 38, DARK)
	title.size = title_panel.size
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_panel.add_child(title)

	# subtítulo
	var sub_panel := Panel.new()
	sub_panel.position = Vector2(180, 88)
	sub_panel.size = Vector2(600, 36)
	sub_panel.add_theme_stylebox_override("panel", Style.box(Color("1a1410"), BROWN, 3))
	add_child(sub_panel)
	subtitle = Style.label("Quem vai jogar?", 22, CREAM)
	subtitle.size = sub_panel.size
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub_panel.add_child(subtitle)

	# cartas dos caçadores
	for i in Game.characters.size():
		cards.append(_make_card(i, Game.characters[i]))

	# botão VOLTAR (celular e mouse)
	var back_btn := Button.new()
	back_btn.text = "< VOLTAR"
	back_btn.position = Vector2(30, 580)
	back_btn.size = Vector2(200, 46)
	back_btn.focus_mode = Control.FOCUS_NONE
	Style.style_button(back_btn)
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)

	# botão de baixo
	var start_panel := Panel.new()
	start_panel.position = Vector2(255, 580)
	start_panel.size = Vector2(450, 46)
	start_panel.add_theme_stylebox_override("panel", Style.box(CREAM, BROWN, 4))
	add_child(start_panel)
	start_label = Style.label("PRESSIONE START", 24, DARK)
	start_label.size = start_panel.size
	start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	start_panel.add_child(start_label)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 20
	add_child(fade_layer)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.size = Vector2(960, 640)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade)

	# primeiro jogável fica selecionado
	for i in cards.size():
		if bool(cards[i].ch.get("jogavel", true)):
			index = i
			break
	_refresh()

	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 0.5)
	await tw.finished
	locked = false


func _make_card(i: int, ch: Dictionary) -> Dictionary:
	var col: int = i % COLS
	var row: int = floori(float(i) / float(COLS))
	var playable: bool = bool(ch.get("jogavel", true))

	var p := Panel.new()
	p.position = Vector2(GRID_X + col * (CARD_W + GAP_X), GRID_Y + row * (CARD_H + GAP_Y))
	p.size = Vector2(CARD_W, CARD_H)
	p.gui_input.connect(_on_card_input.bind(i))
	add_child(p)

	var pic_bg := ColorRect.new()
	pic_bg.color = GREEN
	pic_bg.position = Vector2(10, 10)
	pic_bg.size = Vector2(118, 186)
	pic_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(pic_bg)

	var path := "res://Assets/Portraits/%s.png" % str(ch.id)
	if playable and ResourceLoader.exists(path):
		var pic := TextureRect.new()
		pic.texture = load(path)
		pic.position = Vector2(10, 10)
		pic.size = Vector2(118, 186)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(pic)

	var name_text: String = str(ch.curto).to_upper() if playable else "RESERVADO"
	var name_label := Style.label(name_text, 24 if playable else 20, DARK)
	name_label.position = Vector2(138, 12)
	p.add_child(name_label)

	if playable:
		var role := Style.label(str(ch.funcao), 18, BROWN)
		role.position = Vector2(138, 44)
		p.add_child(role)
		var perk := Style.label(str(ch.habilidade), 16, DARK)
		perk.position = Vector2(138, 78)
		perk.size = Vector2(142, 110)
		perk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p.add_child(perk)
	else:
		var soon := Style.label("Em breve!", 16, BROWN)
		soon.position = Vector2(138, 44)
		p.add_child(soon)
		p.modulate = Color(0.75, 0.75, 0.75)

	return {"panel": p, "ch": ch}


func _refresh() -> void:
	for i in cards.size():
		var selected: bool = i == index
		var border: Color = SELECTED if selected else BROWN
		var width: int = 7 if selected else 4
		(cards[i].panel as Panel).add_theme_stylebox_override("panel", Style.box(CREAM, border, width))
	var ch: Dictionary = cards[index].ch
	if confirming:
		subtitle.text = "Jogar com %s?" % str(ch.curto)
		start_label.text = Game.dica("Z: CONFIRMAR    X: VOLTAR", "TOQUE DE NOVO PARA CONFIRMAR")
	else:
		subtitle.text = "Quem vai jogar?"
		start_label.text = Game.dica("PRESSIONE START", "TOQUE NO CAÇADOR")


func _process(_delta: float) -> void:
	if locked:
		return
	if Input.is_action_just_pressed("interact"):
		_choose()
	elif Input.is_action_just_pressed("cancel"):
		if confirming:
			confirming = false
			_refresh()
		else:
			_go(TITLE_SCENE)
	elif Input.is_action_just_pressed("move_left"):
		_move(-1)
	elif Input.is_action_just_pressed("move_right"):
		_move(1)
	elif Input.is_action_just_pressed("move_up"):
		_move(-COLS)
	elif Input.is_action_just_pressed("move_down"):
		_move(COLS)


func _on_back_pressed() -> void:
	if locked:
		return
	if confirming:
		confirming = false
		_refresh()
	else:
		_go(TITLE_SCENE)


func _move(delta: int) -> void:
	var target: int = index + delta
	if target < 0 or target >= cards.size():
		return
	index = target
	confirming = false
	_refresh()


func _on_card_input(ev: InputEvent, i: int) -> void:
	if locked:
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if i != index:
			index = i
			confirming = false
			_refresh()
		_choose()


func _choose() -> void:
	var ch: Dictionary = cards[index].ch
	if not bool(ch.get("jogavel", true)):
		subtitle.text = "Esta vaga está reservada!"
		await get_tree().create_timer(1.2).timeout
		_refresh()
		return
	if not confirming:
		confirming = true
		_refresh()
		return
	Game.choose_character(str(ch.id))
	Game.save_game(Game.START_MAP, Game.START_TILE)
	_go(WORLD_SCENE)


func _go(path: String) -> void:
	locked = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.4)
	await tw.finished
	get_tree().change_scene_to_file(path)
