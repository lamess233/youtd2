class_name BuffType
extends Node


# BuffType stores buff parameters and can be used to create
# buff instances. It's possible to define a custom BuffType
# by subclassing.
# 
# Buffs can have event handlers. To add an event handler,
# define a handler function in your subclass and call the
# appropriate add_event_handler function. All handler
# functions are called with one parameter Event which passes
# information about the event.
#
# NOTE: BuffType needs to be Node so that it can be used as
# event handler for Buffs. Buff event handlers must be Node
# because buff's need to connect to Node's tree_exited()
# signal for correct "cleanup" event logic.


class CommonHandlerData:
	var handler: Callable
	var event_type: Event.Type

class PeriodicHandlerData:
	var handler: Callable
	var period: float

class RangeHandlerData:
	var handler: Callable
	var radius: float
	var target_type: TargetType


var _unique_name: String
var _time_base: float
var _time_level_add: float
var _friendly: bool
var _modifier: Modifier = Modifier.new()
var _common_handler_list: Array[CommonHandlerData] = []
var _periodic_handler_list: Array[PeriodicHandlerData] = []
var _range_handler_list: Array[RangeHandlerData] = []
var _aura_type_list: Array[AuraType] = []
var _tooltip_text: String = ""
var _buff_icon: String = ""
var _buff_icon_color: Color = Color.GRAY
var _defined_custom_buff_icon_color: bool = false
var _is_hidden: bool = false
var _stacking_behavior_is_enabled: bool = true
var _is_aura: bool = false


#########################
###     Built-in      ###
#########################

# NOTE: if your script creates multiple BuffType's, then
# each BuffType should be created with a different
# "variable_name" arg. Examples: "poison_bt", "curse_bt".
func _init(variable_name: String, time_base: float, time_level_add: float, friendly: bool, parent: Node):
	parent.add_child(self)

#	NOTE: add path of parent script to ensure uniqueness
	var parent_script: Script = parent.get_script()
	var parent_script_path: String = parent_script.get_path()
	_unique_name = "%s-%s" % [parent_script_path, variable_name]

	_time_base = time_base
	_time_level_add = time_level_add
	_friendly = friendly


#########################
###       Public      ###
#########################

# Base apply function. Overrides time parameters from
# init(). Returns the new buff that was applied or currently
# active buff if it has higher priority due to stacking
# behavior.
#
# NOTE: buffs must be applied after the unit has been added
# to scene tree, after add_child() was called.
# 
# NOTE: buffType.applyAdvanced() in JASS
func apply_advanced(caster: Unit, target: Unit, level: int, power: int, time: float) -> Buff:
	if _stacking_behavior_is_enabled:
		var higher_prio_buff: Buff = _do_stacking_behavior(target, level, power)

		if higher_prio_buff != null:
			return higher_prio_buff

	var buff: Buff = Buff.new()
	buff._caster = caster
	buff._level = level
	buff._power = power
	buff._target = target
	buff._modifier = _modifier
	buff._time = time
	buff._friendly = _friendly
	buff._buff_type_name = _unique_name
	buff._tooltip_text = _tooltip_text
	buff._is_hidden = _is_hidden
	buff._buff_icon = _buff_icon
	buff._buff_icon_color = _buff_icon_color

	if _is_aura:
		buff.set_is_purgable(false)

	if _defined_custom_buff_icon_color:
		buff._buff_icon_color = _buff_icon_color
	elif get_parent() is TowerBehavior && caster is Tower:
		var tower: Tower = caster as Tower
		var element: Element.enm = tower.get_element()
		var element_color: Color = Element.get_color(element)

		buff._buff_icon_color = element_color
	else:
		buff._buff_icon_color = Color.GRAY

	tree_exited.connect(buff._on_buff_type_tree_exited)

	for handler in _common_handler_list:
		buff._add_event_handler(handler.event_type, handler.handler)

	for handler in _periodic_handler_list:
		buff._add_periodic_event(handler.handler, handler.period)

	for handler in _range_handler_list:
		buff._add_event_handler_unit_comes_in_range(handler.handler, handler.radius, handler.target_type)

	for aura_type in _aura_type_list:
		buff._add_aura(aura_type)

#	NOTE: need to handle cases where scripts attempt to add
#	buff to a unit which is in the process of getting
#	deleted. In such cases, still create the buff to be able
#	to return it and avoid null errors but don't add the
#	buff to the unit. Adding buff to unit while unit is
#	getting removed from tree causes Godot "parent is busy"
#	error.
	var target_is_active: bool = target.is_inside_tree() && !target.is_queued_for_deletion()
	if target_is_active:
		target._add_buff_internal(buff)
		target.add_child(buff)
	else:
#		NOTE: set _cleanup_done to true because no cleanup
#		is needed. Buff was never added to tree, so _ready()
#		wasn't called, so buff's CREATE event wasn't
#		triggered.
		buff._cleanup_done = true
		buff.queue_free()

	return buff


# NOTE: buffType.applyCustomPower() in JASS
func apply_custom_power(caster: Unit, target: Unit, level: int, power: int) -> Buff:
	var time: float = _time_base + _time_level_add * level

	var buff: Buff = apply_advanced(caster, target, level, power, time)

	return buff


# Base apply function. Overrides time parameters from init().
# 
# NOTE: buffType.applyCustomTimed() in JASS
func apply_custom_timed(caster: Unit, target: Unit, level: int, time: float) -> Buff:
	var buff: Buff = apply_advanced(caster, target, level, level, time)

	return buff


# Apply using time parameters that were defined in init()
# 
# NOTE: buffType.apply() in JASS
func apply(caster: Unit, target: Unit, level: int) -> Buff:
	var time: float = _time_base + _time_level_add * level

	var buff: Buff = apply_custom_timed(caster, target, level, time)

	return buff


# Apply overriding time parameters from init() and without
# specifying level. This is a convenience function
# 
# NOTE: buffType.applyOnlyTimed() in JASS
func apply_only_timed(caster: Unit, target: Unit, time: float) -> Buff:
	var buff: Buff = apply_custom_timed(caster, target, 0, time)
	
	return buff


# NOTE: buffType.applyToUnitPermanent() in JASS
func apply_to_unit_permanent(caster: Unit, target: Unit, level: int) -> Buff:
	var buff: Buff = apply_custom_timed(caster, target, level, -1.0)
	buff.set_is_purgable(false)

	return buff


func add_event_handler(event_type: Event.Type, handler: Callable):
	var data: CommonHandlerData = CommonHandlerData.new()
	data.handler = handler
	data.event_type = event_type

	_common_handler_list.append(data)


# NOTE: buffType.addPeriodicEvent() in JASS
func add_periodic_event(handler: Callable, period: float):
	var data: PeriodicHandlerData = PeriodicHandlerData.new()
	data.handler = handler
	data.period = period

	_periodic_handler_list.append(data)


# NOTE: buffType.addEventOnUnitComesInRange() in JASS
func add_event_on_unit_comes_in_range(handler: Callable, radius: float, target_type: TargetType):
	var data: RangeHandlerData = RangeHandlerData.new()
	data.handler = handler
	data.radius = radius
	data.target_type = target_type

	_range_handler_list.append(data)


# NOTE: buffType.addEventOnCleanup() in JASS
func add_event_on_cleanup(handler: Callable):
	add_event_handler(Event.Type.CLEANUP, handler)


# NOTE: buffType.addEventOnCreate() in JASS
func add_event_on_create(handler: Callable):
	add_event_handler(Event.Type.CREATE, handler)


# NOTE: buffType.addEventOnUpgrade() in JASS
func add_event_on_upgrade(handler: Callable):
	add_event_handler(Event.Type.UPGRADE, handler)


# NOTE: buffType.addEventOnRefresh() in JASS
func add_event_on_refresh(handler: Callable):
	add_event_handler(Event.Type.REFRESH, handler)


# NOTE: buffType.addEventOnDeath() in JASS
func add_event_on_death(handler: Callable):
	add_event_handler(Event.Type.DEATH, handler)


# NOTE: buffType.addEventOnKill() in JASS
func add_event_on_kill(handler: Callable):
	add_event_handler(Event.Type.KILL, handler)


# NOTE: buffType.addEventOnLevelUp() in JASS
func add_event_on_level_up(handler: Callable):
	add_event_handler(Event.Type.LEVEL_UP, handler)


# NOTE: buffType.addEventOnAttack() in JASS
func add_event_on_attack(handler: Callable):
	add_event_handler(Event.Type.ATTACK, handler)


# NOTE: buffType.addEventOnAttacked() in JASS
func add_event_on_attacked(handler: Callable):
	add_event_handler(Event.Type.ATTACKED, handler)


# This event handler will be called when buffed unit deals
# attack damage (not spell damage!). Note that this event
# can't recurse. If your handler deals attack damage, that
# will not trigger another DAMAGE event.
# NOTE: buffType.addEventOnDamage() in JASS
func add_event_on_damage(handler: Callable):
	add_event_handler(Event.Type.DAMAGE, handler)


# This event handler will be called when buffed unit
# receives attack damage (not spell damage!).
# NOTE: buffType.addEventOnDamaged() in JASS
func add_event_on_damaged(handler: Callable):
	add_event_handler(Event.Type.DAMAGED, handler)


# NOTE: buffType.setEventOnExpire() in JASS
func add_event_on_expire(handler: Callable):
	add_event_handler(Event.Type.EXPIRE, handler)


# NOTE: buffType.addEventOnSpellCasted() in JASS
func add_event_on_spell_casted(handler: Callable):
	add_event_handler(Event.Type.SPELL_CAST, handler)


# NOTE: buffType.addEventOnSpellTargeted() in JASS
func add_event_on_spell_targeted(handler: Callable):
	add_event_handler(Event.Type.SPELL_TARGET, handler)


# NOTE: buffType.addEventOnPurge() in JASS
func add_event_on_purge(handler: Callable):
	add_event_handler(Event.Type.PURGE, handler)


func add_aura(aura_type: AuraType):
	_aura_type_list.append(aura_type)


# NOTE: this is useful in rare cases like trigger buffs and
# aura carrier buffs
func disable_stacking_behavior():
	_stacking_behavior_is_enabled = false


#########################
###      Private      ###
#########################

# This f-n will return null if new buff can be applied. It
# returns an active buff if new buff cannot be applied due
# to stacking behavior. In addition, this f-n modifies the
# active buff in certain cases.
# 
# NOTE: the stacking logic has to be in the exact way as
# defined here. Changing this logic might break some tower
# and item scripts.
func _do_stacking_behavior(target: Unit, new_level: int, new_power: int) -> Buff:
	var active_buff: Buff = target.get_buff_of_type(self)

	if active_buff == null:
#		NOTE: no active buff, create new buff
		return null

	var active_level: int = active_buff.get_level()

	if new_level > active_level:
#		NOTE: upgrade active buff, no new buff
		active_buff._upgrade_by_new_buff(new_level, new_power)

		return active_buff
	elif new_level == active_level:
#		NOTE: refresh active buff, no new buff
		active_buff._refresh_by_new_buff()

		return active_buff
	else :
#		(new_level < active_level)
#		NOTE: keep active buff, no new buff
		return active_buff


#########################
### Setters / Getters ###
#########################

func get_unique_name() -> String:
	return _unique_name


# Defines a modifier which will be applied to target unit.
# Note that unlike modifiers applied via Unit.add_modifier()
# function, buff modifiers will not react to unit level ups.
# The strength of buff modifiers depends on buff's power.
# Buff power is defined when buff is applied and can be
# manually modified later via Buff.set_power(). Buff power
# may also change when a stronger buff of same type is
# applied on top of an old buff. The most common case is to
# set buff power to caster level and leave it unchanged
# for the duration of the buff.
# NOTE: buffType.setBuffModifier() in JASS
func set_buff_modifier(modifier: Modifier):
	_modifier = modifier


# This tooltip will be displayed when the buff is applied to
# a unit and player hovers the mouse over the buff icon.
# Note that this should be plain text, rich text format not
# supported.
func set_buff_tooltip(tooltip: String):
	_tooltip_text = tooltip


# NOTE: buffType.setBuffIcon() in JASS
func set_buff_icon(buff_icon: String):
	_buff_icon = buff_icon


# NOTE: if you don't define a color and bufftype belongs to
# tower, then buff will use the color of the tower element.
func set_buff_icon_color(color: Color):
	_defined_custom_buff_icon_color = true
	_buff_icon_color = color


# NOTE: this f-n does nothing. According to original youtd
# engine docs, stacking group is supposed to make it so that
# different buff types do not stack with each other. Checked
# tower and item scripts and all calls to setStackingGroup()
# use unique strings so this f-n serves no purpose.
# 
# NOTE: buffType.setStackingGroup() in JASS
func set_stacking_group(_stacking_group: String):
	pass


# TODO: implement. Probably need to display this effect on
# buffed unit while buff is active.
# 
# NOTE: buffType.setSpecialEffectSimple() in JASS
func set_special_effect_simple(_effect: String):
	pass


# NOTE: if a buff is hidden, it will not be displayed in the
# unit menu. Note that for development purposes, you can
# force hidden buffs to be shown via config.
func set_hidden():
	_is_hidden = true


#########################
###       Static      ###
#########################

# NOTE: BuffType.createAuraEffectType() in JASS
static func create_aura_effect_type(type: String, friendly: bool, parent: Node) -> BuffType:
	var buff_type: BuffType = BuffType.new(type, 0.0, 0.0, friendly, parent)
	buff_type._is_aura = true

	return buff_type
