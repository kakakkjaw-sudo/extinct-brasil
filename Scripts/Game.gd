extends Node
## Autoload "Game": ações de teclado, utilidades globais e estado da partida.
##
## Controles:
##   Setas / WASD ........ andar
##   Z / Enter / Espaço .. interagir, avançar texto
##   X / Esc ............. voltar, fechar
##   C / I ............... abrir a ECODEX (precisa do ECOMAX)
##   M / Q ............... abrir a lista de MISSÕES (precisa do ECOMAX)
##   F9 .................. reiniciar a ECODEX e as missões (modo teste)
##   F10 ................. liga/desliga os controles de toque na tela (modo teste no PC)
##
## No celular os controles de toque ficam no autoload TouchControls.

signal touch_changed

const SAVE_PATH := "user://game_save.json"
const START_MAP := "lab"
const START_TILE := Vector2i(7, 8)

var characters: Array = []          # lista de Data/equipe.json
var player_id: String = "felipe"    # caçador escolhido
var has_ecomax: bool = false
var intro_done: bool = false
var resume: bool = false            # true quando veio de "Continuar"
var saved_map: String = START_MAP
var saved_tile: Vector2i = START_TILE
var touch_on: bool = false          # controles de toque ligados (celular/tablet)
var _touch_locked: bool = false     # true depois do F10: não liga sozinho de novo


func _ready() -> void:
	_add_action("move_up", [KEY_UP, KEY_W])
	_add_action("move_down", [KEY_DOWN, KEY_S])
	_add_action("move_left", [KEY_LEFT, KEY_A])
	_add_action("move_right", [KEY_RIGHT, KEY_D])
	_add_action("interact", [KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E])
	_add_action("cancel", [KEY_X, KEY_ESCAPE, KEY_BACKSPACE])
	_add_action("ecodex", [KEY_C, KEY_I])
	_add_action("missions", [KEY_M, KEY_Q])
	_add_action("debug_reset", [KEY_F9])
	_add_action("toggle_touch", [KEY_F10])
	touch_on = _detect_touch()
	var data = read_json("res://Data/equipe.json")
	if data is Array:
		characters = data


func _add_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action_name, ev)


# ------------------------------------------------------------------ toque
func _detect_touch() -> bool:
	return DisplayServer.is_touchscreen_available() \
		or OS.has_feature("android") or OS.has_feature("ios") \
		or OS.has_feature("web_android") or OS.has_feature("web_ios")


func _input(event: InputEvent) -> void:
	# se o aparelho não foi reconhecido como touch, o primeiro toque de verdade liga os controles
	if event is InputEventScreenTouch and not touch_on and not _touch_locked:
		touch_on = true
		touch_changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_touch"):
		_touch_locked = true
		touch_on = not touch_on
		touch_changed.emit()


## Simula um aperto rápido de "interact" (usado quando a pessoa toca na tela
## para avançar um diálogo).
func tap_interact() -> void:
	var down := InputEventAction.new()
	down.action = "interact"
	down.pressed = true
	down.strength = 1.0
	Input.parse_input_event(down)
	await get_tree().create_timer(0.06).timeout
	var up := InputEventAction.new()
	up.action = "interact"
	up.pressed = false
	Input.parse_input_event(up)


## Texto de dica que muda conforme o aparelho: dica("tecla C", "botão ECODEX").
func dica(teclado: String, toque: String) -> String:
	return toque if touch_on else teclado


## Lê um arquivo JSON do projeto e devolve o conteúdo (Array ou Dictionary).
func read_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Não foi possível abrir: " + path)
		return null
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data == null:
		push_error("JSON inválido: " + path)
	return data


# ------------------------------------------------------------ personagens
func get_character(id: String) -> Dictionary:
	for c in characters:
		if str(c.id) == id:
			return c
	return {}


func player_data() -> Dictionary:
	return get_character(player_id)


## Primeiro nome do caçador escolhido (ex.: "Felipe").
func hero_name() -> String:
	return str(player_data().get("curto", "Felipe"))


func choose_character(id: String) -> void:
	if not get_character(id).is_empty():
		player_id = id


# ----------------------------------------------------------- nova partida
func new_game() -> void:
	has_ecomax = false
	intro_done = false
	resume = false
	saved_map = START_MAP
	saved_tile = START_TILE
	for key in get_meta_list():
		if str(key).begins_with("talked_"):
			remove_meta(key)
	Ecodex.reset()
	Quests.reset()


# ------------------------------------------------------------- salvamento
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(map_id: String = "", tile: Vector2i = Vector2i(-1, -1)) -> void:
	if map_id != "":
		saved_map = map_id
	if tile.x >= 0:
		saved_tile = tile
	var d := {
		"version": 1,
		"player_id": player_id,
		"has_ecomax": has_ecomax,
		"intro_done": intro_done,
		"map": saved_map,
		"x": saved_tile.x,
		"y": saved_tile.y,
		"quests": Quests.to_dict(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(d))
	f.close()


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if not (d is Dictionary):
		return false
	var pid := str(d.get("player_id", "felipe"))
	player_id = pid if not get_character(pid).is_empty() else "felipe"
	has_ecomax = bool(d.get("has_ecomax", false))
	intro_done = bool(d.get("intro_done", false))
	saved_map = str(d.get("map", START_MAP))
	saved_tile = Vector2i(int(d.get("x", START_TILE.x)), int(d.get("y", START_TILE.y)))
	var q = d.get("quests", {})
	if q is Dictionary:
		Quests.from_dict(q)
	resume = true
	return true
