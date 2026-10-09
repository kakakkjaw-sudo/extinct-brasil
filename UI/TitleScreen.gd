extends Node2D
## Tela inicial: arte do jogo + menu NOVO JOGO / CONTINUAR / OPÇÕES.
## A arte (Assets/UI/title.png) já traz o título e a caixa do menu; o jogo só
## desenha o cursor por cima e cuida das teclas.

const Style := preload("res://UI/Style.gd")

const OPTION_Y := [435.0, 478.0, 521.0]   # centro de cada opção na arte (960x640)
const CURSOR_X := 656.0
const MENU_X_MIN := 636.0                 # caixa do menu na arte (para tocar nas opções)
const MENU_X_MAX := 930.0
const SELECT_SCENE := "res://UI/CharacterSelect.tscn"
const WORLD_SCENE := "res://World/World.tscn"

var index: int = 0
var locked: bool = true
var showing_msg: bool = false
var cursor: Polygon2D
var msg_panel: Panel
var msg_label: Label
var fade: ColorRect


func _ready() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://Assets/UI/title.png")
	bg.size = Vector2(960, 640)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(bg)

	cursor = Polygon2D.new()
	cursor.polygon = PackedVector2Array([Vector2(0, 0), Vector2(0, 26), Vector2(18, 13)])
	cursor.color = Color(0.12, 0.12, 0.16)
	add_child(cursor)
	_place_cursor()

	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	msg_panel = Style.panel(Rect2(150, 170, 660, 300))
	msg_panel.visible = false
	ui.add_child(msg_panel)
	msg_label = Style.label("", 24)
	msg_label.position = Vector2(24, 18)
	msg_label.size = Vector2(612, 260)
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_panel.add_child(msg_label)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 20
	add_child(fade_layer)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.size = Vector2(960, 640)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade)

	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 0.6)
	await tw.finished
	locked = false


## Toque / clique direto nas opções do menu (celular e mouse).
func _input(event: InputEvent) -> void:
	if locked:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if showing_msg:
		showing_msg = false
		msg_panel.visible = false
		return
	var p: Vector2 = event.position
	if p.x < MENU_X_MIN or p.x > MENU_X_MAX:
		return
	for i in OPTION_Y.size():
		if absf(p.y - float(OPTION_Y[i])) <= 21.5:
			index = i
			_place_cursor()
			_choose()
			return


func _place_cursor() -> void:
	cursor.position = Vector2(CURSOR_X, float(OPTION_Y[index]) - 13.0)


func _process(_delta: float) -> void:
	if locked:
		return
	if showing_msg:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("cancel"):
			showing_msg = false
			msg_panel.visible = false
		return
	if Input.is_action_just_pressed("move_up"):
		index = (index + OPTION_Y.size() - 1) % OPTION_Y.size()
		_place_cursor()
	elif Input.is_action_just_pressed("move_down"):
		index = (index + 1) % OPTION_Y.size()
		_place_cursor()
	elif Input.is_action_just_pressed("interact"):
		_choose()


func _choose() -> void:
	match index:
		0:
			Game.new_game()
			_go(SELECT_SCENE)
		1:
			if Game.load_game():
				_go(WORLD_SCENE)
			else:
				_show_message("Nenhum jogo salvo ainda.\n\nComece um NOVO JOGO!\n\n(%s)" % Game.dica("Z para fechar", "Toque para fechar"))
		2:
			if Game.touch_on:
				_show_message("CONTROLES NO CELULAR\n\nDirecional na tela: andar\nA: interagir / avançar texto\nB: voltar\nECODEX e MISSÕES: botões no topo\nToque na tela: avançar diálogos\n\n(Toque para fechar)")
			else:
				_show_message("CONTROLES\n\nSetas ou WASD: andar\nZ, Enter ou Espaço: interagir\nX ou Esc: voltar\nC: ECODEX    M: MISSÕES\nF9: reiniciar progresso (teste)\nF10: controles de toque (teste)\n\n(Z para fechar)")


func _show_message(text: String) -> void:
	msg_label.text = text
	msg_panel.visible = true
	showing_msg = true


func _go(path: String) -> void:
	locked = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.4)
	await tw.finished
	get_tree().change_scene_to_file(path)
