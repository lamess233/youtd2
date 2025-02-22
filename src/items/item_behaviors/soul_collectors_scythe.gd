extends ItemBehavior


var multiboard: MultiboardValues


func load_triggers(triggers: BuffType):
	triggers.add_event_on_kill(on_kill)


func item_init():
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Crit Bonus")


func on_create():
	item.user_real = 0


func on_drop():
	item.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_DAMAGE, -item.user_real)


func on_pickup():
	item.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_DAMAGE, item.user_real)


func on_kill(_event: Event):
	if item.user_real < 3:
		item.get_carrier().modify_property(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.005)
		item.user_real = item.user_real + 0.005


func on_tower_details() -> MultiboardValues:
	var crit_damage_bonus_text: String = "x" + Utils.format_float(item.user_real, 3)
	multiboard.set_value(0, crit_damage_bonus_text)

	return multiboard
