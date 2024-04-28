extends TowerBehavior


# NOTE: reworked original script. Origin script uses
# Buff.addAbility() to add multishot temporarily. Can't do
# that with Youtd2 engine so instead we use buff's
# create/cleanup events and modify target count there.

# NOTE: the multishot count is a bit confusing. Description
# says tower "gains a 5 target multishot". This means that
# bonus is +4 so that total is 5. Not that bonus is +5.


var hellfire_bt: BuffType
var liquid_fire_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Hellfire[/color]\n"
	text += "When the Fire Lord attacks there is a 25% chance that it gains a 5 target multishot and 25% bonus attackspeed for 7.5 seconds. Cannot retrigger!\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.2 seconds duration\n"
	text += "+0.4% attackspeed\n"
	text += "+0.2% chance\n"
	text += "+1 target at level 15 and 25\n"
	text += " \n"

	text += "[color=GOLD]Liquid Fire[/color]\n"
	text += "When the Fire Lord damages a creep it will be set on fire, dealing 500 spelldamage per second and increasing the damage it takes from fire towers by 10%. The liquid fire lasts 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+50 spelldamage per second "
	text += "+0.1 seconds duration\n"
	text += "+0.4% bonus damage from fire\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Hellfire[/color]\n"
	text += "When the Fire Lord attacks there is a chance that it gains a multishot ability.\n"
	text += " \n"

	text += "[color=GOLD]Liquid Fire[/color]\n"
	text += "When the Fire Lord damages a creep it will be set on fire.\n"


	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func tower_init():
	liquid_fire_bt = BuffType.new("liquid_fire_bt", 5, 0.1, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.25, 0.004)
	mod.add_modification(Modification.Type.MOD_DMG_FROM_FIRE, 0.10, 0.004)
	liquid_fire_bt.set_buff_modifier(mod)
	liquid_fire_bt.add_periodic_event(liquid_fire_periodic, 1.0)
	liquid_fire_bt.set_buff_icon("res://Resources/Textures/GenericIcons/flame.tres")
	liquid_fire_bt.set_buff_tooltip("Liquid Fire\nDeals damage over time and increases damage taken from Fire towers.")

	hellfire_bt = BuffType.new("hellfire_bt", 7.5, 0.2, true, self)
	hellfire_bt.set_buff_icon("res://Resources/Textures/GenericIcons/mighty_force.tres")
	hellfire_bt.add_event_on_create(hellfire_on_create)
	hellfire_bt.add_event_on_cleanup(hellfire_on_cleanup)
	hellfire_bt.set_buff_tooltip("Hellfire\nAttacks extra targets and increases attack speed.")


func on_attack(_event: Event):
	var level: int = tower.get_level()
	var hellfire_chance: float = 0.25 + 0.002 * level

	if !tower.calc_chance(hellfire_chance):
		return

	var tower_already_has_hellfire: bool = tower.get_buff_of_type(hellfire_bt) != null

	if tower_already_has_hellfire:
		return

	CombatLog.log_ability(tower, null, "Hellfire")

	hellfire_bt.apply(tower, tower, level)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	liquid_fire_bt.apply(tower, target, level)


func liquid_fire_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var target: Unit = buff.get_buffed_unit()
	var damage: float = 500 + 50 * buff.get_level()

	tower.do_spell_damage(target, damage, tower.calc_spell_crit_no_bonus())


# NOTE: it is important that we add and subtract from target
# count. Setting target count to a value directly would be
# incorrect because there are other buffs which also add to
# target count and we need to take care to work well
# together with them.
func hellfire_on_create(event: Event):
	var level: int = tower.get_level()
	var buff: Buff = event.get_buff()

	var target_count_bonus: int = 4
	if level >= 15:
		target_count_bonus += 1
	if level == 25:
		target_count_bonus += 1

	buff.user_int = target_count_bonus

	var current_target_count: int = tower.get_target_count()
	var new_target_count: int = current_target_count + target_count_bonus
	tower.set_target_count(new_target_count)


func hellfire_on_cleanup(event: Event):
	var buff: Buff = event.get_buff()
	var target_count_bonus: int = buff.user_int

	var current_target_count: int = tower.get_target_count()
	var new_target_count: int = current_target_count - target_count_bonus
	tower.set_target_count(new_target_count)
