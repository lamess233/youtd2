extends TowerBehavior


var coals_bt : BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {power = 0, duration = 7.5},
		2: {power = 50, duration = 8.5},
		3: {power = 100, duration = 9.5},
		4: {power = 150, duration = 10.5},
		5: {power = 200, duration = 11.5},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var bonus_crit: String = Utils.format_percent((0.15 + _stats.power * 0.001), 2)
	var duration: String = Utils.format_float(_stats.duration, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Hot Coals"
	ability.icon = "res://resources/icons/fire/fire_bowl_02.tres"
	ability.description_short = "Gains increased crit chance on kill.\n"
	ability.description_full = "Whenever this tower kills a creep it gains %s bonus crit chance for %s seconds.\n" % [bonus_crit, duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.05 sec duration\n" \
	+ "+0.3% crit chance\n"
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.15, 0.001)
#	0.0 time since I will apply it custom timed
	coals_bt = BuffType.new("coals_bt ", 0.0, 0.0, true, self)
	coals_bt.set_buff_modifier(m)
	coals_bt.set_buff_icon("res://resources/icons/GenericIcons/burning_meteor.tres")
	coals_bt.set_stacking_group("boekie_coals")
	coals_bt.set_buff_tooltip("Hot Coals\nIncreases critical chance.")


func on_kill(_event: Event):
	var lvl: int = tower.get_level()
	coals_bt.apply_custom_timed(tower, tower, lvl * 3, _stats.duration + 0.05 * lvl)
