extends TowerBehavior


var slow_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {slow_value = 75, slow_duration = 2.0, aoe_range = 250, aoe_damage = 150, aoe_damage_add = 7.5},
		2: {slow_value = 90, slow_duration = 3.0, aoe_range = 300, aoe_damage = 500, aoe_damage_add = 25},
		3: {slow_value = 110, slow_duration = 4.0, aoe_range = 350, aoe_damage = 1250, aoe_damage_add = 62.5},
		4: {slow_value = 140, slow_duration = 5.0, aoe_range = 400, aoe_damage = 2500, aoe_damage_add = 125},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var aoe_damage: String = Utils.format_float(_stats.aoe_damage, 2)
	var aoe_range: String = Utils.format_float(_stats.aoe_range, 2)
	var slow_value: String = Utils.format_percent(_stats.slow_value / 1000.0, 2)
	var slow_duration: String = Utils.format_float(_stats.slow_duration, 2)
	var aoe_damage_add: String = Utils.format_float(_stats.aoe_damage_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Ice Nova"
	ability.icon = "res://Resources/Icons/misc5/ice_icon.tres"
	ability.description_short = "Has a chance to deal AoE damage and slow creeps around the target.\n"
	ability.description_full = "Damaged targets have a 20%% chance to get blasted by an ice nova, dealing %s damage and slowing units in %s range by %s for %s seconds. Has a 30%% bonus chance to crit.\n" % [aoe_damage, aoe_range, slow_value, slow_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% chance\n" \
	+ "+%s damage\n" % [aoe_damage_add]
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	var m: Modifier = Modifier.new()

	slow_bt = BuffType.new("slow_bt", 0, 0, false, self)
	m.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)
	slow_bt.set_buff_modifier(m)
	slow_bt.set_buff_icon("res://Resources/Icons/GenericIcons/foot_trip.tres")
	slow_bt.set_buff_tooltip("Slowed\nReduces movement speed.")


func on_damage(event: Event):
	if !tower.calc_chance(0.2 + tower.get_level() * 0.004):
		return

	var targ: Unit = event.get_target()
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), targ, _stats.aoe_range)
	var next: Unit

	CombatLog.log_ability(tower, targ, "Ice Nova")

	while true:
		next = it.next()

		if next == null:
			break

		slow_bt.apply_custom_timed(tower, next, _stats.slow_value, _stats.slow_duration)

	var damage: float = _stats.aoe_damage + _stats.aoe_damage_add * tower.get_level()
	tower.do_spell_damage_aoe_unit(targ, _stats.aoe_range, damage, tower.calc_spell_crit(0.3, 0.0), 0)
	SFX.sfx_at_unit("FrostNovaTarget.mdl", targ)
