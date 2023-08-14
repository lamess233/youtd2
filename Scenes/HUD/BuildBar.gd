extends GridContainer


# Map of tower id's => tower buttons. Tower buttons are
# "stacks" and may contain more than one tower. Buttons
# should be always created inside a dedicated container,
# which means you should call the parent of a button if you
# want to change the visual part of it.
@onready var _tower_buttons: Dictionary = {}


var _current_element: Element.enm = Element.enm.NONE : set = set_element, get = get_element
var current_size: String


func _ready():
	BuildTower.tower_built.connect(_on_Tower_built)
	EventBus.game_mode_was_chosen.connect(_on_game_mode_was_chosen)
	TowerDistribution.rolling_starting_towers.connect(_on_rolling_starting_towers)
	TowerDistribution.random_tower_distributed.connect(_on_random_tower_distributed)


func _add_all_towers():
	print_verbose("Start adding all towers to BuildBar.")

	var first_tier_towers: Array = Properties.get_tower_id_list_by_filter(Tower.CsvProperty.TIER, str(1))

	for tower_id in first_tier_towers:
		var is_released: bool = TowerProperties.is_released(tower_id)
		if !is_released:
			continue

		add_tower_button(tower_id)

#	NOTE: call set_element() to show towers for currently
#	selected element. 
	set_element(_current_element)

	print_verbose("BuildBar has added all towers.")


func add_tower_button(tower_id):
	if _tower_buttons.has(tower_id):
		var tower_button: TowerButton = _tower_buttons[tower_id]
		var new_count: int = tower_button.get_count() + 1
		tower_button.set_count(new_count)

		return

	var tower_button = TowerButton.make(tower_id)
	var button_container = UnitButtonContainer.make()
	button_container.add_child(tower_button)
	
	_tower_buttons[tower_id] = tower_button

	var tower_element: Element.enm = TowerProperties.get_element(tower_id)
	var tower_should_be_visible: bool = tower_element == _current_element
	button_container.set_visible(tower_should_be_visible)
	add_child(button_container)


func remove_tower_button(tower_id):
	var button: TowerButton = _tower_buttons[tower_id]
	var button_container: UnitButtonContainer = button.get_parent()

	var tower_button: TowerButton = _tower_buttons[tower_id]
	var new_count: int = tower_button.get_count() - 1
	tower_button.set_count(new_count)

	var no_more_towers_in_stack: bool = new_count == 0

	if no_more_towers_in_stack:
		_tower_buttons.erase(tower_id)
		remove_child(button_container)


func get_element() -> Element.enm:
	return _current_element

func set_element(element: Element.enm):
	_current_element = element
	
	for tower_button in _tower_buttons.values():
		tower_button.get_parent().hide()
	
	var available_towers_for_element = _get_available_tower_buttons_for_element(element)
	
	for tower_id in available_towers_for_element:
		_tower_buttons[tower_id].get_parent().show()


func _on_Tower_built(tower_id):
	match Globals.game_mode:
		GameMode.enm.BUILD: return
		GameMode.enm.RANDOM_WITH_UPGRADES: remove_tower_button(tower_id)
		GameMode.enm.TOTALLY_RANDOM: remove_tower_button(tower_id)


func _get_available_tower_buttons_for_element(element: Element.enm) -> Array:
	var element_string: String = Element.convert_to_string(element)
	var tower_id_list = Properties.get_tower_id_list_by_filter(Tower.CsvProperty.ELEMENT, element_string)
	
	var res: Array = []
	for tower_id in tower_id_list:
		if _tower_buttons.has(tower_id):
			res.append(tower_id)
	
	return res


func _on_game_mode_was_chosen():
	if Globals.game_mode == GameMode.enm.BUILD:
		_add_all_towers()


func _on_rolling_starting_towers():
	var tower_list: Array = _tower_buttons.keys()

	for tower in tower_list:
		remove_tower_button(tower)


func _on_random_tower_distributed(tower_id: int):
	add_tower_button(tower_id)
