extends Node2D
## Jogador (caçador escolhido em Game.player_id): movimento em grade, 4 direções, tile por tile.

signal step_finished(tile: Vector2i)

const TILE := 16
const STEP_TIME := 0.16
const ZOOM := 4.0

var world = null            # referência ao World (para checar colisão)
var tile: Vector2i = Vector2i.ZERO
var facing: Vector2i = Vector2i.DOWN
var moving: bool = false
var sprite: Sprite2D
var camera: Camera2D
var _alt: int = 0


func _ready() -> void:
	z_index = 1
	sprite = Sprite2D.new()
	sprite.texture = load("res://Assets/Characters/%s.png" % Game.player_id)
	sprite.hframes = 3
	sprite.vframes = 4
	sprite.centered = false
	add_child(sprite)
	camera = Camera2D.new()
	camera.position = Vector2(TILE / 2.0, TILE / 2.0)
	camera.zoom = Vector2(ZOOM, ZOOM)
	add_child(camera)


func place(t: Vector2i, dir: Vector2i) -> void:
	tile = t
	position = Vector2(t * TILE)
	moving = false
	set_facing(dir)


func set_facing(dir: Vector2i) -> void:
	facing = dir
	sprite.frame = _row(dir) * 3


func _row(dir: Vector2i) -> int:
	if dir == Vector2i.LEFT:
		return 1
	if dir == Vector2i.RIGHT:
		return 2
	if dir == Vector2i.UP:
		return 3
	return 0


func try_move(dir: Vector2i) -> void:
	set_facing(dir)
	var target: Vector2i = tile + dir
	if world.is_blocked(target):
		return
	moving = true
	_alt = 1 - _alt
	sprite.frame = _row(dir) * 3 + 1 + _alt
	var tw := create_tween()
	tw.tween_property(self, "position", Vector2(target * TILE), STEP_TIME)
	await tw.finished
	tile = target
	sprite.frame = _row(dir) * 3
	moving = false
	step_finished.emit(tile)
