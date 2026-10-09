extends CanvasLayer
## Lista de MISSÕES do ECOMAX (tecla M). Uso: await mission_screen.open()

const Style := preload("res://UI/Style.gd")

const DONE_COLOR := Color("58d080")
const FUTURE_COLOR := Color("6a7890")

var box: VBoxContainer
var _tapped: bool = false


func _ready() -> void:
	layer = 8
	visible = false
	var back := ColorRect.new()
	back.color = Color(0, 0, 0, 0.6)
	back.size = Vector2(960, 640)
	back.gui_input.connect(_on_back_input)
	add_child(back)
	var panel := Style.panel(Rect2(40, 30, 880, 580))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE   # o toque passa para o fundo e fecha
	add_child(panel)
	var title := Style.label("ECOMAX - MISSÕES", 30, Style.ACCENT)
	title.position = Vector2(24, 14)
	panel.add_child(title)
	box = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.position = Vector2(24, 68)
	box.size = Vector2(832, 440)
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var hint := Style.label(Game.dica("X, M ou Z: fechar", "Toque na tela para fechar"), 18)
	hint.position = Vector2(24, 530)
	panel.add_child(hint)


func open() -> void:
	_rebuild()
	_tapped = false
	visible = true
	while true:
		await get_tree().process_frame
		if _tapped or Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("missions") \
				or Input.is_action_just_pressed("interact"):
			break
	visible = false


func _on_back_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_tapped = true


func _line(text: String, color: Color, size: int = 22) -> Label:
	var l := Style.label(text, size, color)
	l.custom_minimum_size = Vector2(832, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(l)
	return l


func _rebuild() -> void:
	for c in box.get_children():
		c.queue_free()
	var done: int = mini(Quests.index, Quests.missions.size())
	_line("Concluídas: %d / %d      Cápsulas extras: +%d" % [done, Quests.missions.size(), Quests.bonus_capsules()], Style.TEXT, 20)
	for i in Quests.missions.size():
		var m: Dictionary = Quests.missions[i]
		if i < Quests.index:
			_line("[OK]  %s" % str(m.titulo), DONE_COLOR)
		elif i == Quests.index:
			_line("[>>]  %s   (%d/%d)" % [str(m.titulo), Quests.progress(m), Quests.goal(m)], Style.ACCENT, 24)
			_line("        " + str(m.descricao), Style.TEXT, 19)
			if Quests.is_complete(m):
				_line("        Cumprida! Fale com o Prof. Proença no laboratório.", DONE_COLOR, 19)
		else:
			_line("[  ]  %s" % str(m.titulo), FUTURE_COLOR)
	if Quests.all_done():
		_line("Todas as missões foram cumpridas. Parabéns!", DONE_COLOR, 22)
