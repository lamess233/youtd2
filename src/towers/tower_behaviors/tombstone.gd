extends TowerBehavior


func get_tier_stats() -> Dictionary:
	return {
		1: {chance_base = 0.008, chance_add = 0.0015},
		2: {chance_base = 0.010, chance_add = 0.0017},
		3: {chance_base = 0.012, chance_add = 0.0020},
		4: {chance_base = 0.014, chance_add = 0.0022},
		5: {chance_base = 0.016, chance_add = 0.0024},
		6: {chance_base = 0.020, chance_add = 0.0025},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_damage(event: Event):
	if !tower.calc_chance(_stats.chance_base + tower.get_level() * _stats.chance_add):
		return

	var creep: Unit = event.get_target()
	var size: int = creep.get_size()

	if size < CreepSize.enm.CHAMPION:
		CombatLog.log_ability(tower, creep, "Tomb's Curse")
		tower.kill_instantly(creep)
		Effect.create_simple_at_unit("res://src/effects/death_coil.tscn", creep)
