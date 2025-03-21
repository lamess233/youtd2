class_name AuraType

# AuraType stores information about an aura. Should be used
# to create Aura instances. Create an AuraType and set it's
# properties, then pass AuraType to Tower.add_aura() or
# BuffType.add_aura().

# NOTE: level and level_add parameters define how aura level
# scales with tower level.
# aura level = level + level_add * tower_level
# - Setting level to 0 and level_add to 1 will make aura
#   level the same as tower level.
# - Setting level to 100 and level_add to 2 will make aura
#   level start at 200 and incrase by 2 for each tower
#   level.


var name_english: String = ""
var name: String = ""
var icon: String = ""
var description_short: String = ""
var description_long: String = ""

# NOTE: if this value is set to true, the aura won't be
# shown as an ability icon in tower menu and won't be
# included in tower tooltip.
var is_hidden: bool = false

var aura_range: float = 10.0
var target_type: TargetType = null
var target_self: bool = false
var level: int = 0
var level_add: int = 0
var aura_effect: BuffType = null

var _include_invisible: bool = false


func make(caster: Unit) -> Aura:
	var aura: Aura = Preloads.aura_scene.instantiate()
	aura._aura_range = get_range(caster.get_player())
	aura._target_type = target_type
	aura._target_self = target_self
	aura._level = level
	aura._level_add = level_add
	aura._aura_effect = aura_effect
	aura._include_invisible = _include_invisible

	aura._caster = caster

	return aura


func get_range(player: Player) -> float:
	var original_range: float = aura_range
	var builder: Builder = player.get_builder()
	var builder_range_bonus: float = builder.get_range_bonus()
	var total_range: float = original_range + builder_range_bonus

	return total_range


static func make_aura_type(aura_id: int, object_with_buff_var: Object) -> AuraType:
	var aura: AuraType = AuraType.new()

	aura.name_english = AuraProperties.get_name_english(aura_id)
	aura.name = AuraProperties.get_aura_name(aura_id)
	aura.icon = AuraProperties.get_icon_path(aura_id)
	aura.description_short = AuraProperties.get_description_short(aura_id)
	aura.description_long = AuraProperties.get_description_long(aura_id)
	aura.aura_range = AuraProperties.get_aura_range(aura_id)
	aura.target_type = AuraProperties.get_target_type(aura_id)
	aura.target_self = AuraProperties.get_target_self(aura_id)
	aura.level = AuraProperties.get_level(aura_id)
	aura.level_add = AuraProperties.get_level_add(aura_id)
	aura.is_hidden = AuraProperties.get_is_hidden(aura_id)

	var buff_type_string: String = AuraProperties.get_buff_type(aura_id)
	var buff_type: BuffType = object_with_buff_var.get(buff_type_string)
	if buff_type == null:
		push_error("Failed to find buff type for aura. Buff type = %s, aura id = %d" % [buff_type_string, aura_id])
	aura.aura_effect = buff_type
	
	return aura
