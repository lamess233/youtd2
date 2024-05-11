extends ItemBehavior


func get_ability_description() -> String:
	var hel_string: String = ArmorType.convert_to_colored_string(ArmorType.enm.HEL)

	var text: String = ""

	text += "[color=GOLD]Unstable Current[/color]\n"
	text += "Deals an additional 25%% damage as spell damage against creeps with %s armor.\n" % hel_string

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var T: Creep = event.get_target()

	if T.get_armor_type() == ArmorType.enm.HEL:
		event.damage = event.damage * 1.25
		SFX.sfx_on_unit("DispelMagicTarget.mdl", T, Unit.BodyPart.CHEST)
