extends ItemBehavior


var power_bt: BuffType


func load_triggers(triggers: BuffType):
    triggers.add_event_on_damage(on_damage)


func load_modifier(modifier: Modifier):
    modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.05, 0.0)
    modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.10, 0.0)
    modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.10, 0.0)


func item_init():
    power_bt = BuffType.new("power_bt", 5, 0, false, self)
    power_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
    power_bt.set_buff_tooltip("Power of the Sword\nReduces armor.")
    var mod: Modifier = Modifier.new()
    mod.add_modification(Modification.Type.MOD_ARMOR, 0.0, -0.2)
    power_bt.set_buff_modifier(mod)


func on_damage(event: Event):
    var tower: Tower = item.get_carrier()

    if event.is_main_target() == true:
        if Utils.rand_chance(Globals.synced_rng, 0.5):
            power_bt.apply(tower, event.get_target(), 25 + tower.get_level())
        else:
            power_bt.apply(tower, event.get_target(), 50 + tower.get_level())
