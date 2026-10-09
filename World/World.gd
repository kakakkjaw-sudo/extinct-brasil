extends Node2D
## Mundo 2D top-down: desenha o mapa em tiles, controla jogador, NPCs,
## portais entre mapas, encontros com criaturas no capim alto e as
## conversas com o Prof. Proença (ECOMAX + missões).

const TILE := 16
const PlayerScript := preload("res://World/Player.gd")
const NpcScript := preload("res://World/Npc.gd")
const DialogBoxScript := preload("res://UI/DialogBox.gd")
const EncounterScript := preload("res://UI/Encounter.gd")
const EcodexScreenScript := preload("res://UI/EcodexScreen.gd")
const MissionScreenScript := preload("res://UI/MissionScreen.gd")
const Style := preload("res://UI/Style.gd")

# Legenda dos mapas -> posição do tile em Assets/Tiles/tileset.png
const TILE_INDEX := {
	".": 0, "g": 1, "=": 2, "T": 3, "~": 4, "W": 5, "R": 6, "D": 7,
	"f": 8, "m": 9, "x": 10, "P": 11, "S": 12, "r": 13, "L": 14,
}
const BLOCKED := "T~WRmSrL"
const ENCOUNTER_TILE := "g"
const ENCOUNTER_CHANCE := 0.2
const MIN_STEPS_BETWEEN_ENCOUNTERS := 3

const PROFESSOR_ID := "proenca"
const PROFESSOR_NAME := "Prof. Proença"

const FINAL_LINES := [
	"Você cumpriu TODAS as missões e completou a ECODEX! Que expedição incrível.",
	"O projeto EXTINCT: BRASIL nunca teve exploradores melhores. Parabéns, equipe!",
	"Continue explorando o Pleistoceno: sempre há algo novo para observar nos encontros.",
]

var tileset: Texture2D
var maps: Dictionary = {}
var current_id: String = ""
var grid: Array = []
var npcs: Dictionary = {}
var player = null
var busy: bool = true
var steps_since_encounter: int = 0

var dialog
var encounter
var ecodex_screen
var mission_screen
var fade: ColorRect
var banner: Label
var quest_banner: Label
var objective: Label
var hint: Label


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tileset = load("res://Assets/Tiles/tileset.png")
	var data = Game.read_json("res://Data/maps.json")
	if data is Dictionary:
		maps = data
	_build_ui()
	player = PlayerScript.new()
	player.world = self
	add_child(player)
	player.step_finished.connect(_on_step_finished)

	var start_map: String = Game.START_MAP
	var start_tile: Vector2i = Game.START_TILE
	var start_dir: Vector2i = Vector2i.UP
	if Game.resume and maps.has(Game.saved_map):
		start_map = Game.saved_map
		start_tile = Game.saved_tile
		start_dir = Vector2i.DOWN
	_load_map(start_map, start_tile, start_dir)
	_refresh_hud()
	await _fade(0.0, 0.8)
	if not Game.intro_done:
		await dialog.say(_intro_lines(), "Narração")
		Game.intro_done = true
		Game.save_game(current_id, player.tile)
	_show_banner(maps[current_id].name)
	_check_quests()
	await _release()


func _intro_lines() -> Array:
	var c: Dictionary = Game.player_data()
	return [
		"EXTINCT: BRASIL - THE TIME HUNTERS",
		"Seis jovens exploradores brasileiros construíram a TEMPORAL CAPSULE, uma tecnologia capaz de abrir portais para o passado.",
		"A missão: encontrar animais que realmente existiram, estudá-los sem machucá-los e registrar tudo na ECODEX.",
		"Você é %s, %s. Procure o PROF. PROENÇA aqui no laboratório: ele tem um equipamento importante para você." % [
			str(c.get("curto", "Felipe")), str(c.get("papel", "líder da equipe"))],
	]


func _build_ui() -> void:
	dialog = DialogBoxScript.new()
	add_child(dialog)
	encounter = EncounterScript.new()
	add_child(encounter)
	ecodex_screen = EcodexScreenScript.new()
	add_child(ecodex_screen)
	mission_screen = MissionScreenScript.new()
	add_child(mission_screen)

	var hud := CanvasLayer.new()
	hud.layer = 4
	add_child(hud)
	banner = Style.label("", 30, Style.TEXT)
	Style.outlined(banner)
	banner.position = Vector2(0, 18)
	banner.size = Vector2(960, 44)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.modulate.a = 0.0
	hud.add_child(banner)
	quest_banner = Style.label("", 24, Style.ACCENT)
	Style.outlined(quest_banner)
	quest_banner.position = Vector2(0, 64)
	quest_banner.size = Vector2(960, 36)
	quest_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_banner.modulate.a = 0.0
	hud.add_child(quest_banner)
	objective = Style.label("", 18, Style.ACCENT)
	Style.outlined(objective)
	objective.position = Vector2(14, 578)
	hud.add_child(objective)
	hint = Style.label("Setas/WASD: andar   Z: interagir   C: ECODEX   M: MISSÕES", 18)
	Style.outlined(hint)
	hint.position = Vector2(14, 606)
	hud.add_child(hint)
	Game.touch_changed.connect(_apply_touch_layout)
	_apply_touch_layout()

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 20
	add_child(fade_layer)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.position = Vector2.ZERO
	fade.size = Vector2(960, 640)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade)


## No celular o canto inferior esquerdo é do direcional: a dica de teclado some
## e o objetivo sobe para o topo.
func _apply_touch_layout() -> void:
	hint.visible = not Game.touch_on
	objective.position = Vector2(14, 104) if Game.touch_on else Vector2(14, 578)


## Usado pelo TouchControls: o direcional só aparece com o mundo livre.
func touch_active() -> bool:
	return not busy


# ------------------------------------------------------------------ mapas
func _load_map(id: String, tile: Vector2i, dir: Vector2i) -> void:
	current_id = id
	Quests.visit(id)
	var m: Dictionary = maps[id]
	grid = m.tiles
	for n in npcs.values():
		n.queue_free()
	npcs.clear()
	for d in m.get("npcs", []):
		# o caçador escolhido é o jogador: não aparece também como NPC
		if str(d.get("id", "")) == Game.player_id:
			continue
		var n = NpcScript.new()
		n.setup(d)
		add_child(n)
		npcs[n.tile] = n
	player.place(tile, dir)
	var w: int = (grid[0] as String).length() * TILE
	var h: int = grid.size() * TILE
	player.camera.limit_left = 0
	player.camera.limit_top = 0
	player.camera.limit_right = w
	player.camera.limit_bottom = h
	player.camera.force_update_scroll()
	steps_since_encounter = 0
	queue_redraw()


func _draw() -> void:
	for y in grid.size():
		var row: String = grid[y]
		for x in row.length():
			var idx: int = TILE_INDEX.get(row[x], 0)
			draw_texture_rect_region(
				tileset,
				Rect2(x * TILE, y * TILE, TILE, TILE),
				Rect2(idx * TILE, 0, TILE, TILE))


func is_blocked(t: Vector2i) -> bool:
	if t.y < 0 or t.y >= grid.size():
		return true
	var row: String = grid[t.y]
	if t.x < 0 or t.x >= row.length():
		return true
	if row[t.x] in BLOCKED:
		return true
	return npcs.has(t)


# ------------------------------------------------------------------ loop
func _process(_delta: float) -> void:
	if busy or player.moving:
		return
	if Input.is_action_just_pressed("debug_reset"):
		Ecodex.reset()
		Quests.reset()
		Game.has_ecomax = false
		Game.save_game(current_id, player.tile)
		_refresh_hud()
		_show_banner("ECODEX e missões reiniciadas")
		return
	if Input.is_action_just_pressed("ecodex"):
		_open_ecodex()
		return
	if Input.is_action_just_pressed("missions"):
		_open_missions()
		return
	if Input.is_action_just_pressed("interact"):
		_interact()
		return
	var dir := Vector2i.ZERO
	if Input.is_action_pressed("move_up"):
		dir = Vector2i.UP
	elif Input.is_action_pressed("move_down"):
		dir = Vector2i.DOWN
	elif Input.is_action_pressed("move_left"):
		dir = Vector2i.LEFT
	elif Input.is_action_pressed("move_right"):
		dir = Vector2i.RIGHT
	if dir != Vector2i.ZERO:
		player.try_move(dir)


func _release() -> void:
	# espera 1 frame para a tecla que fechou um diálogo não disparar outra ação
	await get_tree().process_frame
	_refresh_hud()
	busy = false


func _interact() -> void:
	var t: Vector2i = player.tile + player.facing
	if not npcs.has(t):
		return
	busy = true
	var n = npcs[t]
	n.face_towards(player.tile)
	if n.npc_id == PROFESSOR_ID:
		await _talk_professor()
	else:
		await dialog.say(n.get_lines(), n.npc_name)
	await _release()


func _open_ecodex() -> void:
	if not Game.has_ecomax:
		_show_banner("Pegue o ECOMAX com o %s" % PROFESSOR_NAME)
		return
	busy = true
	await ecodex_screen.open()
	await _release()


func _open_missions() -> void:
	if not Game.has_ecomax:
		_show_banner("Pegue o ECOMAX com o %s" % PROFESSOR_NAME)
		return
	busy = true
	await mission_screen.open()
	await _release()


# ------------------------------------------------- Prof. Proença / missões
func _talk_professor() -> void:
	var h: String = Game.hero_name()
	if not Game.has_ecomax:
		await dialog.say([
			"Ah, %s! Que bom que você chegou. Sou o Professor Proença, coordenador do projeto EXTINCT: BRASIL." % h,
			"A TEMPORAL CAPSULE abre portais para o passado, mas ninguém viaja no tempo sem equipamento de campo.",
			"Tome: este é o ECOMAX, o meu aparelho de pesquisa mais novo!",
		], PROFESSOR_NAME)
		Game.has_ecomax = true
		_refresh_hud()
		await dialog.say(["%s recebeu o ECOMAX!" % h])
		await dialog.say([
			"Ele guarda a ECODEX (%s) e a lista de MISSÕES (%s), e avisa quando você cumprir uma tarefa." % [
				Game.dica("aperte C", "botão ECODEX"), Game.dica("aperte M", "botão MISSÕES")],
			"Agora preste atenção no que você precisa fazer:",
		], PROFESSOR_NAME)
		await _announce_mission()
	elif Quests.all_done():
		await dialog.say([
			"Todas as missões foram cumpridas! Não tenho mais nada a pedir, %s." % h,
			"Mas nunca é demais estudar mais um pouco: cada encontro com uma criatura ensina algo novo.",
		], PROFESSOR_NAME)
	elif Quests.current_complete():
		await _finish_mission()
	else:
		var m: Dictionary = Quests.current()
		await dialog.say([
			"Missão atual: %s (%d/%d)." % [str(m.titulo), Quests.progress(m), Quests.goal(m)],
			str(m.descricao),
			"Quando terminar, volte aqui. Você também pode conferir tudo no ECOMAX (%s)." % Game.dica("tecla M", "botão MISSÕES"),
		], PROFESSOR_NAME)
	Game.save_game(current_id, player.tile)
	_refresh_hud()
	_check_quests()


func _announce_mission() -> void:
	var m: Dictionary = Quests.current()
	await dialog.say([
		"Sua missão: %s." % str(m.titulo).to_upper(),
		str(m.descricao),
		"Volte a falar comigo quando terminar. Pode conferir a lista no ECOMAX (%s)." % Game.dica("tecla M", "botão MISSÕES"),
	], PROFESSOR_NAME)


func _finish_mission() -> void:
	var m: Dictionary = Quests.current()
	var lines: Array = ["Missão cumprida: %s! O ECOMAX já me enviou os dados." % str(m.titulo)]
	lines.append_array(m.get("recompensa", []))
	await dialog.say(lines, PROFESSOR_NAME)
	var caps: int = int(m.get("capsulas", 0))
	if caps > 0:
		await dialog.say(["%s ganhou +%d CÁPSULA(S) em cada encontro!" % [Game.hero_name(), caps]])
	Quests.advance()
	if Quests.all_done():
		await dialog.say(FINAL_LINES, PROFESSOR_NAME)
	else:
		await dialog.say(["Pronto para a próxima missão?"], PROFESSOR_NAME)
		await _announce_mission()


func _check_quests() -> void:
	if Game.has_ecomax and Quests.check_new():
		_show_quest_banner("MISSÃO CUMPRIDA! Fale com o %s" % PROFESSOR_NAME)


func _refresh_hud() -> void:
	if not Game.has_ecomax:
		objective.text = "Objetivo: fale com o %s" % PROFESSOR_NAME
	elif Quests.all_done():
		objective.text = "Todas as missões cumpridas!"
	else:
		var m: Dictionary = Quests.current()
		objective.text = "Missão: %s (%d/%d)" % [str(m.titulo), Quests.progress(m), Quests.goal(m)]


# ------------------------------------------------------- passos / eventos
func _on_step_finished(t: Vector2i) -> void:
	var m: Dictionary = maps[current_id]
	for w in m.get("warps", []):
		if int(w.x) == t.x and int(w.y) == t.y:
			busy = true
			if str(w.to) == "pleistoceno" and not Game.has_ecomax:
				await _portal_locked(t)
				return
			await _do_warp(w)
			return
	var enc: Array = m.get("encounters", [])
	if enc.is_empty():
		return
	var row: String = grid[t.y]
	if row[t.x] == ENCOUNTER_TILE:
		steps_since_encounter += 1
		if steps_since_encounter >= MIN_STEPS_BETWEEN_ENCOUNTERS and randf() < ENCOUNTER_CHANCE:
			busy = true
			await _start_encounter(enc)


func _portal_locked(t: Vector2i) -> void:
	await dialog.say([
		"O portal está desligado. Sem o ECOMAX não dá para viajar no tempo com segurança.",
		"Volte ao laboratório e fale com o %s." % PROFESSOR_NAME,
	], "Portal")
	player.place(t - player.facing, player.facing)
	await _release()


func _do_warp(w: Dictionary) -> void:
	await _fade(1.0, 0.25)
	var dir := Vector2i.DOWN
	match str(w.get("dir", "down")):
		"left":
			dir = Vector2i.LEFT
		"right":
			dir = Vector2i.RIGHT
		"up":
			dir = Vector2i.UP
	_load_map(str(w.to), Vector2i(int(w.tx), int(w.ty)), dir)
	Game.save_game(current_id, player.tile)
	await _fade(0.0, 0.25)
	_show_banner(maps[current_id].name)
	_check_quests()
	await _release()


func _pick_species(enc: Array) -> String:
	var total := 0
	for e in enc:
		total += int(e.peso)
	var roll := randi_range(1, total)
	for e in enc:
		roll -= int(e.peso)
		if roll <= 0:
			return str(e.id)
	return str(enc[0].id)


func _start_encounter(enc: Array) -> void:
	steps_since_encounter = 0
	await _fade(1.0, 0.25)
	var sp: Dictionary = Ecodex.get_species(_pick_species(enc))
	var ground := Color(str(maps[current_id].get("encounter_color", "#78a85a")))
	encounter.start(sp, ground)
	await _fade(0.0, 0.25)
	await encounter.finished
	await _fade(1.0, 0.25)
	encounter.hide_screen()
	await _fade(0.0, 0.25)
	Game.save_game(current_id, player.tile)
	_check_quests()
	await _release()


# ------------------------------------------------------------- utilidades
func _fade(target: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", target, duration)
	await tw.finished


func _show_banner(text: String) -> void:
	banner.text = text
	banner.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.3)
	tw.tween_interval(1.8)
	tw.tween_property(banner, "modulate:a", 0.0, 0.5)


func _show_quest_banner(text: String) -> void:
	quest_banner.text = text
	quest_banner.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(quest_banner, "modulate:a", 1.0, 0.3)
	tw.tween_interval(3.0)
	tw.tween_property(quest_banner, "modulate:a", 0.0, 0.5)
