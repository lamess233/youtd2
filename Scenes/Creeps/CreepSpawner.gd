extends Node


signal creep_spawned(creep: Creep)
signal all_creeps_spawned


const MASS_SPAWN_DELAY_SEC = 0.2
const NORMAL_SPAWN_DELAY_SEC = 0.9
const CREEP_SCENE_INSTANCES_PATHS = {
	"HumanoidAir": "res://Scenes/Creeps/Instances/Humanoid/HumanoidAirCreep.tscn",
	"HumanoidChampion": "res://Scenes/Creeps/Instances/Humanoid/HumanoidChampionCreep.tscn",
	"HumanoidBoss": "res://Scenes/Creeps/Instances/Humanoid/HumanoidBossCreep.tscn",
	"HumanoidMass": "res://Scenes/Creeps/Instances/Humanoid/HumanoidMassCreep.tscn",
	"HumanoidNormal": "res://Scenes/Creeps/Instances/Humanoid/HumanoidNormalCreep.tscn",
	
	"OrcChampion": "res://Scenes/Creeps/Instances/Orc/OrcChampionCreep.tscn",
	"OrcAir": "res://Scenes/Creeps/Instances/Orc/OrcAirCreep.tscn",
	"OrcBoss": "res://Scenes/Creeps/Instances/Orc/OrcBossCreep.tscn",
	"OrcMass": "res://Scenes/Creeps/Instances/Orc/OrcMassCreep.tscn",
	"OrcNormal": "res://Scenes/Creeps/Instances/Orc/OrcNormalCreep.tscn",
	
	"UndeadChampion": "res://Scenes/Creeps/Instances/Undead/UndeadChampionCreep.tscn",
	"UndeadAir": "res://Scenes/Creeps/Instances/Undead/UndeadAirCreep.tscn",
	"UndeadBoss": "res://Scenes/Creeps/Instances/Undead/UndeadBossCreep.tscn",
	"UndeadMass": "res://Scenes/Creeps/Instances/Undead/UndeadMassCreep.tscn",
	"UndeadNormal": "res://Scenes/Creeps/Instances/Undead/UndeadNormalCreep.tscn",
	
	"MagicNormal": "res://Scenes/Creeps/Instances/Magic/MagicNormalCreep.tscn",
	"MagicChampion": "res://Scenes/Creeps/Instances/Magic/MagicChampionCreep.tscn",
	"MagicAir": "res://Scenes/Creeps/Instances/Magic/MagicAirCreep.tscn",
	"MagicBoss": "res://Scenes/Creeps/Instances/Magic/MagicBossCreep.tscn",
	"MagicMass": "res://Scenes/Creeps/Instances/Magic/MagicMassCreep.tscn",
	
	"NatureAir": "res://Scenes/Creeps/Instances/Nature/NatureAirCreep.tscn",
	"NatureBoss": "res://Scenes/Creeps/Instances/Nature/NatureBossCreep.tscn",
	"NatureMass": "res://Scenes/Creeps/Instances/Nature/NatureMassCreep.tscn",
	"NatureNormal": "res://Scenes/Creeps/Instances/Nature/NatureNormalCreep.tscn",
	"NatureChampion": "res://Scenes/Creeps/Instances/Nature/NatureChampionCreep.tscn",
}


# Dict[scene_name -> Resource]
var _creep_scenes: Dictionary
var _creep_spawn_queue: Array[CreepData]
var _scene_load_queue: Array[String] = []
var _loading_scene_is_in_progress: bool = false

@onready var _timer_between_creeps: Timer = $Timer


func _ready():
	_timer_between_creeps.set_autostart(true)
	_timer_between_creeps.set_one_shot(false)
	
	var regex_search = RegEx.new()
	regex_search.compile("^(?!\\.).*$")


func _process(_delta: float):
	if !_scene_load_queue.is_empty():
		if _loading_scene_is_in_progress:
			_process_load_for_creep_scene()
		else:
			_request_load_for_creep_scene()


func _request_load_for_creep_scene():
	var scene_name: String = _scene_load_queue.front()
	var scene_path: String = CREEP_SCENE_INSTANCES_PATHS[scene_name]
	ResourceLoader.load_threaded_request(scene_path, "", false)
	_loading_scene_is_in_progress = true

	print_verbose("Starting to load creep scene: ", scene_name)
	ElapsedTimer.start("Elapsed time for loading creep scene:" + scene_name)


func _process_load_for_creep_scene():
	var scene_name: String = _scene_load_queue.front()
	var scene_path: String = CREEP_SCENE_INSTANCES_PATHS[scene_name]

	var loading_done: bool = ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED

	if loading_done:
		var scene: PackedScene = ResourceLoader.load_threaded_get(scene_path)
		_creep_scenes[scene_name] = scene
		_scene_load_queue.pop_front()
		_loading_scene_is_in_progress = false

		print_verbose("Finished loading creep scene: ", scene_name)
		ElapsedTimer.end_verbose("Elapsed time for loading creep scene:" + scene_name)


# Waits until creep scene is done loading
func _wait_for_load_for_creep_scene(scene_name: String):
	var scene_path: String = CREEP_SCENE_INSTANCES_PATHS[scene_name]

	var scene: PackedScene = ResourceLoader.load_threaded_get(scene_path)
	_creep_scenes[scene_name] = scene
	_scene_load_queue.pop_front()
	_loading_scene_is_in_progress = false


func queue_spawn_creep(creep_data: CreepData):
	assert(creep_data != null, "Tried to spawn null creep.")
	
	_creep_spawn_queue.push_back(creep_data)
	if _timer_between_creeps.is_stopped():
		if creep_data.size == CreepSize.enm.MASS:
			_timer_between_creeps.set_wait_time(MASS_SPAWN_DELAY_SEC)
		elif creep_data.size == CreepSize.enm.NORMAL:
			_timer_between_creeps.set_wait_time(NORMAL_SPAWN_DELAY_SEC)
		print_verbose("Start creep spawn timer with delay [%s]." % _timer_between_creeps.get_wait_time())
		_timer_between_creeps.start()


func generate_creep_for_wave(wave: Wave, creep_size) -> CreepData:
	var creep_size_name = Utils.screaming_snake_case_to_camel_case(CreepSize.enm.keys()[creep_size])
	var creep_race_name = Utils.screaming_snake_case_to_camel_case(CreepCategory.enm.keys()[wave.get_race()])
	var creep_scene_name = creep_race_name + creep_size_name

	var creep_data: CreepData = CreepData.new()
	creep_data.scene_name = creep_scene_name
	creep_data.size = creep_size
	creep_data.wave = wave

#	Queue creep scene for loading. Need to load scenes in
#	the order that they are used. For example if the first
#	wave is mass humanoid creeps, then we load mass humanoid
#	scene first and so on.
# 	NOTE: this assumes that generate_creep_for_wave() is
# 	called in order.
	if !_scene_load_queue.has(creep_scene_name):
		_scene_load_queue.append(creep_scene_name)
		print_verbose("Added creep scene to loading queue:", creep_scene_name)

	return creep_data


func spawn_creep(creep_data: CreepData) -> Creep:
	var creep_size: CreepSize.enm = creep_data.size
	var creep_scene_name: String = creep_data.scene_name
	var wave: Wave = creep_data.wave

# 	NOTE: if creep needs to spawn and it's scene didn't
# 	finish loading in the background yet, then we'll need to
# 	wait for the creep scene to load. This will freeze the
# 	game. Should only happen if the player starts the first
# 	wave immediately after game starts.
	var scene_not_loaded: bool = !_creep_scenes.has(creep_scene_name)

	if scene_not_loaded:
		print_verbose("Creep spawned too early. Waiting for loading of creep scene to finish: ", creep_scene_name)
		_wait_for_load_for_creep_scene(creep_scene_name)

	var creep = _creep_scenes[creep_scene_name].instantiate()

	if creep == null:
		push_error("Could not find a scene for creep size [%s] and race [%]." % [creep_size, wave.get_race()])

		return null

	creep.set_path(wave.get_wave_path())
	creep.set_creep_size(creep_size)
	creep.set_armor_type(wave.get_armor_type())
	creep.set_category(wave.get_race())
	creep.set_base_health(wave.get_base_hp())
	creep.set_spawn_level(wave.get_wave_number())
	creep.death.connect(wave._on_Creep_death.bind(creep))
	creep.reached_portal.connect(Callable(wave, "_on_Creep_reached_portal").bind(creep))

	wave.add_alive_creep(creep)

	Utils.add_object_to_world(creep)
	print_verbose("Creep has been spawned [%s]." % creep)

#	NOTE: buffs must be applied after creep has been added to
#	world
	var special_list: Array[int] = wave.get_specials()
	WaveSpecial.apply_to_creep(special_list, creep)

	return creep


func _on_Timer_timeout():
	if _creep_spawn_queue.is_empty():
		print_verbose("Stop creep spawn. Queue is exhausted.")
		_timer_between_creeps.stop()
		all_creeps_spawned.emit()

		return

	var creep_data: CreepData = _creep_spawn_queue.pop_front()

	var creep: Creep = spawn_creep(creep_data)
	creep_spawned.emit(creep)
