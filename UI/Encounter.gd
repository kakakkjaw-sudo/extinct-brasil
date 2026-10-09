extends CanvasLayer
## Tela de encontro: RASTREAR e CAPTURAR (sem violência).
##
## Evolução da cena de batalha da base original: mesmo layout clássico
## (criatura em cima, caixa de texto embaixo, menu de 4 opções), mas no lugar
## de dano e HP temos uma barra de SINAL DE RASTREIO e a TEMPORAL CAPSULE.
##
## Fluxo: ESCANEAR (grátis, 1x) -> RASTREAR (gasta tempo, sobe o sinal)
##        -> CÁPSULA (chance depende do sinal e da espécie) -> ECODEX.

signal finished(captured: bool)

const Style := preload("res://UI/Style.gd")
const TypeLabelScript := preload("res://UI/TypeLabel.gd")

const MAX_TURNS := 6
const MAX_CAPSULES := 3
const TRACK_LINES := [
	"%s segue pegadas frescas na lama.",
	"%s ouve movimento entre a vegetação e se aproxima devagar.",
	"Marcas em um tronco mostram por onde a criatura passou.",
	"%s observa a criatura de longe, sem fazer barulho.",
]

var species: Dictionary = {}
var tracking: float = 0.0
var turns_left: int = MAX_TURNS
var capsules: int = MAX_CAPSULES
var scanned: bool = false

var ground: ColorRect
var creature: TextureRect
var name_label: Label
var number_label: Label
var status_label: Label
var track_bar: ProgressBar
var msg_label                 # TypeLabel
var menu: GridContainer
var btn_scan: Button
var btn_track: Button
var btn_capsule: Button
var btn_leave: Button
var last_focus: Button
var _bob: Tween


func _ready() -> void:
	layer = 10
	visible = false

	var sky := ColorRect.new()
	sky.color = Color("a8d0e8")
	sky.size = Vector2(960, 640)
	add_child(sky)
	ground = ColorRect.new()
	ground.position = Vector2(0, 330)
	ground.size = Vector2(960, 310)
	add_child(ground)

	creature = TextureRect.new()
	creature.position = Vector2(352, 70)
	creature.size = Vector2(256, 256)
	creature.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	creature.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	creature.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(creature)

	# painel com nome da espécie (canto superior esquerdo)
	var info := Style.panel(Rect2(20, 20, 400, 92))
	add_child(info)
	number_label = Style.label("", 20, Style.ACCENT)
	number_label.position = Vector2(14, 8)
	info.add_child(number_label)
	name_label = Style.label("", 28)
	name_label.position = Vector2(14, 40)
	info.add_child(name_label)

	# painel do sinal de rastreio (canto superior direito)
	var sig := Style.panel(Rect2(540, 20, 400, 130))
	add_child(sig)
	var sig_title := Style.label("SINAL DE RASTREIO", 20, Style.ACCENT)
	sig_title.position = Vector2(14, 8)
	sig.add_child(sig_title)
	track_bar = ProgressBar.new()
	track_bar.position = Vector2(14, 42)
	track_bar.size = Vector2(368, 26)
	track_bar.min_value = 0
	track_bar.max_value = 100
	track_bar.show_percentage = false
	track_bar.add_theme_stylebox_override("background", Style.box(Color("0c1018"), Style.BORDER, 3))
	track_bar.add_theme_stylebox_override("fill", Style.box(Color("58d080"), Color("58d080"), 0))
	sig.add_child(track_bar)
	status_label = Style.label("", 22)
	status_label.position = Vector2(14, 82)
	sig.add_child(status_label)

	# caixa de mensagem (embaixo, esquerda)
	var box := Style.panel(Rect2(30, 450, 570, 170))
	add_child(box)
	msg_label = TypeLabelScript.new()
	msg_label.position = Vector2(20, 16)
	msg_label.size = Vector2(530, 130)
	msg_label.add_theme_font_size_override("font_size", 26)
	box.add_child(msg_label)

	# toque na tela avança o texto (fica ABAIXO do menu, para os botões continuarem tocáveis)
	for p in [info, sig, box]:
		(p as Panel).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tap := Control.new()
	tap.size = Vector2(960, 640)
	tap.mouse_filter = Control.MOUSE_FILTER_STOP
	tap.gui_input.connect(_on_tap)
	add_child(tap)

	# menu de ações (embaixo, direita)
	menu = GridContainer.new()
	menu.columns = 2
	menu.position = Vector2(620, 450)
	menu.size = Vector2(310, 170)
	menu.add_theme_constant_override("h_separation", 8)
	menu.add_theme_constant_override("v_separation", 8)
	add_child(menu)
	btn_scan = _make_button("ESCANEAR", _on_scan)
	btn_track = _make_button("RASTREAR", _on_track)
	btn_capsule = _make_button("CÁPSULA", _on_capsule)
	btn_leave = _make_button("RECUAR", _on_leave)
	last_focus = btn_scan


func _on_tap(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		Game.tap_interact()


func _make_button(label_text: String, handler: Callable) -> Button:
	var b := Button.new()
	b.text = label_text
	b.custom_minimum_size = Vector2(151, 80)
	Style.style_button(b)
	b.pressed.connect(handler)
	menu.add_child(b)
	return b


# ------------------------------------------------------------------ fluxo
func start(sp: Dictionary, ground_color: Color) -> void:
	species = sp
	tracking = 0.0
	var perk: Dictionary = Game.player_data().get("bonus", {})
	turns_left = MAX_TURNS + int(perk.get("tempo", 0))
	capsules = MAX_CAPSULES + int(perk.get("capsulas", 0)) + Quests.bonus_capsules()
	scanned = false
	ground.color = ground_color
	creature.texture = load(str(sp.sprite))
	creature.modulate = Color.WHITE
	creature.position = Vector2(352, 70)
	track_bar.value = 0
	name_label.text = "???"
	number_label.text = "#%03d" % int(sp.numero)
	_update_status()
	_set_menu(false)
	msg_label.start("")
	visible = true
	if _bob:
		_bob.kill()
	_bob = create_tween().set_loops()
	_bob.tween_property(creature, "position:y", 62.0, 0.7)
	_bob.tween_property(creature, "position:y", 70.0, 0.7)

	var is_new: bool = Ecodex.mark_seen(str(sp.id))
	name_label.text = str(sp.nome)
	await _say("Uma criatura temporal apareceu: %s!" % str(sp.nome).to_upper())
	if is_new:
		await _say("Nova espécie descoberta! O registro #%03d foi aberto na ECODEX." % int(sp.numero))
	await _ask()


func hide_screen() -> void:
	get_viewport().gui_release_focus()
	visible = false


func _ask() -> void:
	await _say("O que %s vai fazer?" % Game.hero_name(), false)
	_set_menu(true)


func _set_menu(on: bool) -> void:
	menu.visible = on
	if on:
		last_focus.grab_focus()


func _update_status() -> void:
	status_label.text = "Cápsulas: %d    Tempo: %d" % [capsules, turns_left]


func _add_tracking(amount: float) -> void:
	tracking = clampf(tracking + amount, 0.0, 100.0)
	var tw := create_tween()
	tw.tween_property(track_bar, "value", tracking, 0.5)


## Mostra um texto digitado. Se wait=true, espera o jogador apertar interagir.
func _say(text: String, wait: bool = true) -> void:
	msg_label.start(text)
	while msg_label.typing:
		await get_tree().process_frame
		if Input.is_action_just_pressed("interact"):
			msg_label.skip()
	if wait:
		while true:
			await get_tree().process_frame
			if Input.is_action_just_pressed("interact"):
				break


func _close(captured: bool) -> void:
	if _bob:
		_bob.kill()
	finished.emit(captured)


# ----------------------------------------------------------------- ações
func _on_scan() -> void:
	last_focus = btn_scan
	_set_menu(false)
	if scanned:
		await _say("O scanner já registrou tudo o que podia sobre esta espécie.")
	else:
		scanned = true
		var scan_gain: float = 10.0 + float(Game.player_data().get("bonus", {}).get("escanear", 0))
		_add_tracking(scan_gain)
		await _say("ESCANEAR: %s (%s)." % [str(species.nome), str(species.cientifico)])
		await _say("Habitat: %s. Alimentação: %s." % [str(species.habitat), str(species.alimentacao)])
		await _say("Os dados reforçaram o sinal de rastreio! (+%d)" % int(scan_gain))
	await _ask()


func _on_track() -> void:
	last_focus = btn_track
	_set_menu(false)
	var gain := randi_range(15, 30) + int(Game.player_data().get("bonus", {}).get("rastrear", 0))
	_add_tracking(float(gain))
	await _say(str(TRACK_LINES.pick_random()) % Game.hero_name())
	await _say("O sinal de rastreio aumentou! (+%d)" % gain)
	await _end_turn()


func _on_capsule() -> void:
	last_focus = btn_capsule
	_set_menu(false)
	capsules -= 1
	_update_status()
	await _say("%s lançou a CÁPSULA TEMPORAL!" % Game.hero_name())
	var tw := create_tween()
	for i in 3:
		tw.tween_property(creature, "modulate", Color(0.5, 1.0, 1.0), 0.15)
		tw.tween_property(creature, "modulate", Color.WHITE, 0.15)
	await tw.finished
	var chance := clampf((0.15 + tracking * 0.007) * float(species.facilidade) + float(Game.player_data().get("bonus", {}).get("captura", 0.0)), 0.05, 0.9)
	if randf() < chance:
		await _success()
		return
	await _say("O campo temporal falhou... %s resistiu à cápsula." % str(species.nome))
	if capsules <= 0:
		await _say("Acabaram as cápsulas. A criatura se afastou em segurança.")
		_close(false)
		return
	await _end_turn()


func _on_leave() -> void:
	last_focus = btn_leave
	_set_menu(false)
	await _say("%s recuou em silêncio e a criatura seguiu seu caminho." % Game.hero_name())
	_close(false)


func _end_turn() -> void:
	turns_left -= 1
	_update_status()
	if turns_left <= 0:
		await _say("O sinal temporal enfraqueceu e %s se afastou." % str(species.nome))
		_close(false)
		return
	await _ask()


func _success() -> void:
	Ecodex.mark_captured(str(species.id))
	await _say("A cápsula brilhou e o sinal ficou estável!")
	await _say("%s foi estudada e registrada na ECODEX! (%d/%d)" % [
		str(species.nome), Ecodex.captured_count(), Ecodex.total()])
	await _say("Novos dados liberados: Curiosidade e História.")
	await _say("A criatura foi devolvida em segurança ao seu tempo.")
	_close(true)
