extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 25, damage_add = 1},
		2: {damage = 125, damage_add = 5},
		3: {damage = 375, damage_add = 15},
		4: {damage = 750, damage_add = 30},
		5: {damage = 1500, damage_add = 60},
		6: {damage = 2500, damage_add = 100},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_damage(event: Event):
	if event.is_main_target() && tower.calc_chance(0.15) && !event.get_target().is_immune():
		CombatLog.log_ability(tower, event.get_target(), "Frozen Thorn")

		Effect.create_simple_at_unit("res://src/effects/frost_armor_damage.tscn", event.get_target())
		tower.do_spell_damage(event.get_target(), _stats.damage + _stats.damage_add * tower.get_level(), tower.calc_spell_crit_no_bonus())
