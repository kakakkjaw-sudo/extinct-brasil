extends Node2D
## NPC parado que fala quando o jogador interage. Se "sprite" for vazio,
## o NPC é invisível (usado para placas).

const TILE := 16

var npc_id: String = ""
var npc_name: String = ""
var tile: Vector2i = Vector2i.ZERO
var lines: Array = []
var repeat_lines: Array = []
var sprite: Sprite2D = null


func setup(data: Dictionary) -> void:
	npc_id = str(data.get("id", ""))
	npc_name = str(data.get("name", ""))
	tile = Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))
	lines = data.get("lines", [])
	repeat_lines = data.get("repeat_lines", [])
	position = Vector2(tile * TILE)
	var sheet := str(data.get("sprite", ""))
	if sheet != "":
		sprite = Sprite2D.new()
		sprite.texture = load("res://Assets/Characters/%s.png" % sheet)
		sprite.hframes = 3
		sprite.vframes = 4
		sprite.centered = false
		add_child(sprite)
		face(_dir_from_name(str(data.get("facing", "down"))))


func _dir_from_name(n: String) -> Vector2i:
	match n:
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
		"up":
			return Vector2i.UP
	return Vector2i.DOWN


func face(dir: Vector2i) -> void:
	if sprite == null:
		return
	var row := 0
	if dir == Vector2i.LEFT:
		row = 1
	elif dir == Vector2i.RIGHT:
		row = 2
	elif dir == Vector2i.UP:
		row = 3
	sprite.frame = row * 3


func face_towards(target: Vector2i) -> void:
	face(target - tile)


## Primeira conversa usa "lines"; depois usa "repeat_lines" (se existir).
func get_lines() -> Array:
	var key := "talked_" + npc_id
	if Game.has_meta(key) and not repeat_lines.is_empty():
		return repeat_lines
	Game.set_meta(key, true)
	return lines
