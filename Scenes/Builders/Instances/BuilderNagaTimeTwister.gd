extends Builder


func _get_tower_modifier() -> Modifier:
    var mod: Modifier = Modifier.new()
    mod.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.40, 0.0)
    mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.30, 0.0)

    mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, -0.25, 0.0)
    mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, -0.25, 0.0)

    return mod
