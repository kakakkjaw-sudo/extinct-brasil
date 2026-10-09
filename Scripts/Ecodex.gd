extends Node
## Autoload "Ecodex": a enciclopédia científica de espécies.
##
## Evolução do pipeline "JSON -> objetos" da base original (SaveData.gd):
## os dados das espécies ficam em Data/species.json e o progresso do jogador
## (descoberta / captura) é salvo em user://ecodex_save.json.
##
## Estados de cada espécie:
##   (ausente)  -> ainda não descoberta, aparece como ???
##   "seen"     -> descoberta (viu a criatura): dados básicos liberados
##   "captured" -> estudada com a Temporal Capsule: Curiosidade e História liberadas

signal changed

const SPECIES_PATH := "res://Data/species.json"
const SAVE_PATH := "user://ecodex_save.json"

var species: Array = []
var progress: Dictionary = {}


func _ready() -> void:
	var data = Game.read_json(SPECIES_PATH)
	if data is Array:
		species = data
	_load_progress()


func total() -> int:
	return species.size()


func get_species(id: String) -> Dictionary:
	for sp in species:
		if sp.id == id:
			return sp
	return {}


func is_seen(id: String) -> bool:
	return progress.has(id)


func is_captured(id: String) -> bool:
	return progress.get(id, "") == "captured"


func seen_count() -> int:
	return progress.size()


func captured_count() -> int:
	var n := 0
	for id in progress:
		if progress[id] == "captured":
			n += 1
	return n


## Marca como descoberta. Devolve true se era uma espécie nova.
func mark_seen(id: String) -> bool:
	if progress.has(id):
		return false
	progress[id] = "seen"
	_save_progress()
	changed.emit()
	return true


func mark_captured(id: String) -> void:
	progress[id] = "captured"
	_save_progress()
	changed.emit()


func reset() -> void:
	progress.clear()
	_save_progress()
	changed.emit()


func _save_progress() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(progress))
	f.close()


func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		progress = data
