extends CanvasLayer
## Autoload "TouchControls": controles na tela para celular/tablet.
##
## - Direcional (4 setas) no canto esquerdo, botões A (interagir) e B (voltar) no direito,
##   e atalhos ECODEX / MISSÕES no canto superior direito.
## - Aceita vários dedos ao mesmo tempo (andar com um dedo e apertar A com outro).
## - Os botões "apertam" as mesmas ações do teclado (move_*, interact, cancel, ecodex, missions),
##   então o resto do jogo não precisa saber se é teclado ou toque.
## - Só aparecem no mundo, quando o jogo está livre (sem diálogo, encontro ou menu aberto).
##   Diálogos, encontros, ECODEX e missões têm o próprio toque na tela.
## - Aparecem sozinhos em aparelhos com tela de toque. F10 liga/desliga (para testar no PC).

# Layout (coordenadas da tela do jogo, 960 x 640)
const DPAD_C := Vector2(130, 512)
const KEY := 72.0
const A_C := Vector2(850, 536)
const A_R := 54.0
const B_C := Vector2(748, 590)
const B_R := 42.0
const SHORTCUTS := {
	"ecodex": Rect2(790, 12, 150, 52),
	"missions": Rect2(790, 72, 150, 52),
}
const SHORTCUT_LABEL := {"ecodex": "ECODEX", "missions": "MISSÕES"}
const DEADZONE := 24.0

# Cada ação do jogo também dispara a ação "ui_*" equivalente (para navegar em botões e listas)
const UI_PAIR := {
	"move_up": "ui_up", "move_down": "ui_down",
	"move_left": "ui_left", "move_right": "ui_right",
	"interact": "ui_accept", "cancel": "ui_cancel",
}

const FILL := Color(0.094, 0.125, 0.19, 0.55)
const BORDER := Color(0.94, 0.9, 0.78, 0.8)
const ON := Color(0.91, 0.72, 0.24, 0.9)
const DARK := Color(0.094, 0.125, 0.19, 0.95)

var pressed: Dictionary = {}     # ação -> true enquanto estiver apertada
var _fingers: Dictionary = {}    # índice do dedo -> {"zone": String, "dir": String}
var pad: Node2D
var rotate_layer: CanvasLayer


## Desenha os botões. Fica separado para podermos mexer na transparência do conjunto.
class Pad extends Node2D:
	var ctrl

	func _draw() -> void:
		var c: Vector2 = ctrl.DPAD_C
		var k: float = ctrl.KEY
		var font := ThemeDB.fallback_font
		# direcional
		draw_rect(Rect2(c.x - k / 2, c.y - k / 2, k, k), ctrl.FILL)
		var keys := {
			"move_up": Rect2(c.x - k / 2, c.y - k * 1.5, k, k),
			"move_down": Rect2(c.x - k / 2, c.y + k / 2, k, k),
			"move_left": Rect2(c.x - k * 1.5, c.y - k / 2, k, k),
			"move_right": Rect2(c.x + k / 2, c.y - k / 2, k, k),
		}
		for a in keys:
			var r: Rect2 = keys[a]
			var on: bool = ctrl.pressed.has(a)
			draw_rect(r, ctrl.ON if on else ctrl.FILL)
			draw_rect(r, ctrl.BORDER, false, 4.0)
			var m: Vector2 = r.get_center()
			var pts := PackedVector2Array()
			match a:
				"move_up":
					pts = PackedVector2Array([m + Vector2(0, -16), m + Vector2(-16, 12), m + Vector2(16, 12)])
				"move_down":
					pts = PackedVector2Array([m + Vector2(0, 16), m + Vector2(-16, -12), m + Vector2(16, -12)])
				"move_left":
					pts = PackedVector2Array([m + Vector2(-16, 0), m + Vector2(12, -16), m + Vector2(12, 16)])
				"move_right":
					pts = PackedVector2Array([m + Vector2(16, 0), m + Vector2(-12, -16), m + Vector2(-12, 16)])
			draw_colored_polygon(pts, ctrl.DARK if on else ctrl.BORDER)
		# botões A e B
		_round_button(font, ctrl.A_C, ctrl.A_R, "A", ctrl.pressed.has("interact"))
		_round_button(font, ctrl.B_C, ctrl.B_R, "B", ctrl.pressed.has("cancel"))
		# atalhos
		var alpha := 1.0 if Game.has_ecomax else 0.45
		for a in ctrl.SHORTCUTS:
			var r2: Rect2 = ctrl.SHORTCUTS[a]
			var on2: bool = ctrl.pressed.has(a)
			var fill: Color = ctrl.ON if on2 else ctrl.FILL
			draw_rect(r2, Color(fill.r, fill.g, fill.b, fill.a * alpha))
			var bd: Color = ctrl.BORDER
			draw_rect(r2, Color(bd.r, bd.g, bd.b, bd.a * alpha), false, 4.0)
			var tc: Color = ctrl.DARK if on2 else Color(0.94, 0.9, 0.78, alpha)
			draw_string(font, Vector2(r2.position.x, r2.position.y + 34), str(ctrl.SHORTCUT_LABEL[a]),
				HORIZONTAL_ALIGNMENT_CENTER, r2.size.x, 22, tc)

	func _round_button(font: Font, center: Vector2, r: float, text: String, on: bool) -> void:
		draw_circle(center, r, ctrl.ON if on else ctrl.FILL)
		draw_arc(center, r, 0.0, TAU, 48, ctrl.BORDER, 4.0, true)
		draw_string(font, Vector2(center.x - 30.0, center.y + r * 0.3), text,
			HORIZONTAL_ALIGNMENT_CENTER, 60.0, int(r * 0.8), ctrl.DARK if on else ctrl.BORDER)


func _ready() -> void:
	layer = 3            # abaixo do diálogo (5), do ECOMAX (8), do encontro (10) e da ECODEX (15)
	process_mode = Node.PROCESS_MODE_ALWAYS
	pad = Pad.new()
	pad.ctrl = self
	pad.visible = false
	add_child(pad)
	_build_rotate_notice()


func _build_rotate_notice() -> void:
	rotate_layer = CanvasLayer.new()
	rotate_layer.layer = 30
	rotate_layer.visible = false
	add_child(rotate_layer)
	var back := ColorRect.new()
	back.color = Color(0.05, 0.07, 0.1, 1.0)
	back.size = Vector2(960, 640)
	rotate_layer.add_child(back)
	var l := Label.new()
	l.text = "GIRE O CELULAR\n\npara jogar na horizontal"
	l.add_theme_font_size_override("font_size", 56)
	l.add_theme_color_override("font_color", Color("f0e6c8"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size = Vector2(960, 640)
	rotate_layer.add_child(l)


# ------------------------------------------------------------------ estado
## O jogo está livre para receber o direcional? (o mundo informa isso)
func _world_free() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.has_method("touch_active") and bool(scene.touch_active())


func _process(_delta: float) -> void:
	var win := DisplayServer.window_get_size()
	rotate_layer.visible = Game.touch_on and win.y > int(win.x * 1.05)
	var show_pad: bool = Game.touch_on and _world_free()
	if not show_pad and not _fingers.is_empty():
		_release_all()
	pad.visible = show_pad
	if show_pad:
		pad.queue_redraw()


func _notification(what: int) -> void:
	# app em segundo plano / janela sem foco: solta tudo para o personagem não andar sozinho
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release_all()


# ------------------------------------------------------------------- toque
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
	elif event is InputEventScreenDrag:
		_touch_move(event.index, event.position)


func _zone_at(p: Vector2) -> String:
	if Rect2(DPAD_C - Vector2(KEY * 1.7, KEY * 1.7), Vector2(KEY * 3.4, KEY * 3.4)).has_point(p):
		return "dpad"
	if p.distance_to(A_C) <= A_R + 14.0:
		return "interact"
	if p.distance_to(B_C) <= B_R + 14.0:
		return "cancel"
	for a in SHORTCUTS:
		if (SHORTCUTS[a] as Rect2).grow(6.0).has_point(p):
			return str(a)
	return ""


func _touch_down(index: int, p: Vector2) -> void:
	if not (Game.touch_on and _world_free()):
		return
	var zone := _zone_at(p)
	if zone == "":
		return
	_fingers[index] = {"zone": zone, "dir": ""}
	if zone == "dpad":
		_update_dpad(index, p)
	else:
		_fire(zone, true)


func _touch_move(index: int, p: Vector2) -> void:
	if _fingers.has(index) and _fingers[index].zone == "dpad":
		_update_dpad(index, p)


func _touch_up(index: int) -> void:
	if not _fingers.has(index):
		return
	var f: Dictionary = _fingers[index]
	if f.zone == "dpad":
		if str(f.dir) != "":
			_fire(str(f.dir), false)
	else:
		_fire(str(f.zone), false)
	_fingers.erase(index)


func _update_dpad(index: int, p: Vector2) -> void:
	var v := p - DPAD_C
	var action := ""
	if v.length() >= DEADZONE:
		if absf(v.x) > absf(v.y):
			action = "move_right" if v.x > 0.0 else "move_left"
		else:
			action = "move_down" if v.y > 0.0 else "move_up"
	var f: Dictionary = _fingers[index]
	if str(f.dir) == action:
		return
	if str(f.dir) != "":
		_fire(str(f.dir), false)
	if action != "":
		_fire(action, true)
	f.dir = action


func _release_all() -> void:
	for index in _fingers.keys():
		_touch_up(index)
	_fingers.clear()
	for a in pressed.keys():
		_send(str(a), false)
	pressed.clear()


# ------------------------------------------------------------ ações de entrada
func _fire(action: String, down: bool) -> void:
	_send(action, down)
	if UI_PAIR.has(action):
		_send(str(UI_PAIR[action]), down)
	if down:
		pressed[action] = true
	else:
		pressed.erase(action)


func _send(action: String, down: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = down
	ev.strength = 1.0 if down else 0.0
	Input.parse_input_event(ev)
