extends Node
## Autoload "Quests": missões que o Prof. Proença passa pelo ECOMAX.
##
## As missões ficam em Data/missoes.json, na ordem em que aparecem. Tipos:
##   "visit"    -> visitar o mapa "alvo"
##   "seen"     -> descobrir "meta" espécies (aparecem na ECODEX)
##   "captured" -> estudar "meta" espécies com a cápsula (meta 0 = todas)
## Campo opcional "capsulas": cápsulas extras por encontro ao concluir a missão.

const MISSIONS_PATH := "res://Data/missoes.json"

var missions: Array = []
var index: int = 0              # missão atual (== missions.size() quando acabaram)
var visited: Array = []         # mapas já visitados
var notified: bool = false      # já avisou que a missão atual foi cumprida?


func _ready() -> void:
	var data = Game.read_json(MISSIONS_PATH)
	if data is Array:
		missions = data


func reset() -> void:
	index = 0
	visited.clear()
	notified = false


func all_done() -> bool:
	return index >= missions.size()


func current() -> Dictionary:
	if all_done():
		return {}
	return missions[index]


func visit(map_id: String) -> void:
	if not visited.has(map_id):
		visited.append(map_id)


func goal(m: Dictionary) -> int:
	if str(m.get("tipo", "")) == "visit":
		return 1
	var g: int = int(m.get("meta", 1))
	if g <= 0:
		g = Ecodex.total()
	return g


func progress(m: Dictionary) -> int:
	var value := 0
	match str(m.get("tipo", "")):
		"visit":
			value = 1 if visited.has(str(m.get("alvo", ""))) else 0
		"seen":
			value = Ecodex.seen_count()
		"captured":
			value = Ecodex.captured_count()
	return mini(value, goal(m))


func is_complete(m: Dictionary) -> bool:
	return progress(m) >= goal(m)


func current_complete() -> bool:
	return not all_done() and is_complete(current())


## true UMA vez quando a missão atual acaba de ser cumprida (para avisar o jogador).
func check_new() -> bool:
	if current_complete() and not notified:
		notified = true
		return true
	return false


func advance() -> void:
	index += 1
	notified = false


## Cápsulas extras por encontro, somando as recompensas das missões já entregues.
func bonus_capsules() -> int:
	var total := 0
	for i in mini(index, missions.size()):
		total += int(missions[i].get("capsulas", 0))
	return total


func to_dict() -> Dictionary:
	return {"index": index, "visited": visited, "notified": notified}


func from_dict(d: Dictionary) -> void:
	index = clampi(int(d.get("index", 0)), 0, missions.size())
	visited = (d.get("visited", []) as Array).duplicate()
	notified = bool(d.get("notified", false))
