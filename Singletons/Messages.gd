extends Node

# Functions that display messages to the player. Messages
# will be displayed only if player arg is equal to local
# player. Pass null to player arg to display message to all
# players.

const ERROR_MESSAGE_MAX: int = 3
const ERROR_DELAY_BEFORE_FADE_START: float = 2.0
const ERROR_FADE_DURATION: float = 2.0
const NORMAL_MESSAGE_MAX: int = 10
const NORMAL_DELAY_BEFORE_FADE_START: float = 10.0
const NORMAL_FADE_DURATION: float = 2.0


# Adds an error message to the center of the screen. Note
# that error messages are always colored red.
func add_error(player: Player, text: String):
	var player_match: bool = player == Globals.get_local_player() || player == null
	
	if !player_match:
		return

	var hud: HUD = get_tree().get_root().get_node_or_null("GameScene/UI/HUD")

	if hud == null:
		push_warning("hud is null. You can ignore this warning during game restart.")
		
		return

	var error_message_container: VBoxContainer = hud.get_error_message_container()

	var formatted_text: String = "[center][color=RED]%s[/color][/center]" % text

	var label: RichTextLabel = RichTextLabel.new()
	label.append_text(formatted_text)
	label.fit_content = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_theme_type_variation("RichTextLabelLarge")

	label.modulate = Color.WHITE
	var modulate_tween: Tween = create_tween()
	modulate_tween.tween_property(label, "modulate",
		Color(label.modulate.r, label.modulate.g, label.modulate.b, 0),
		ERROR_FADE_DURATION).set_delay(ERROR_DELAY_BEFORE_FADE_START)

#	NOTE: have to add label under dummy because there's no
#	insert_child() f-n available.
	var first_node_dummy: Control = error_message_container.get_children()[0]
	first_node_dummy.add_sibling(label)

#	NOTE: subtract 1 from size to account for dummy child
	var label_count: int = error_message_container.get_children().size() - 1
	var reached_max: bool = label_count >= ERROR_MESSAGE_MAX + 1

	if reached_max:
		var child_list: Array = error_message_container.get_children()
		var last_label: RichTextLabel = child_list.back()

		error_message_container.remove_child(last_label)
		last_label.queue_free()


# Adds a normal message to the left side of the screen.
func add_normal(player: Player, text: String):
	var player_match: bool = player == Globals.get_local_player() || player == null

	if !player_match:
		return

	var hud: HUD = get_tree().get_root().get_node_or_null("GameScene/UI/HUD")
	
	if hud == null:
		push_warning("hud is null. You can ignore this warning during game restart.")
		
		return
	
	var normal_message_container: VBoxContainer = hud.get_normal_message_container()

	var label: RichTextLabel = RichTextLabel.new()
	label.append_text(text)
	label.fit_content = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_theme_type_variation("RichTextLabelLarge")

	label.modulate = Color.WHITE
	var modulate_tween: Tween = create_tween()
	modulate_tween.tween_property(label, "modulate",
		Color(label.modulate.r, label.modulate.g, label.modulate.b, 0),
		NORMAL_FADE_DURATION).set_delay(NORMAL_DELAY_BEFORE_FADE_START)

	normal_message_container.add_child(label)

	var label_count: int = normal_message_container.get_children().size()
	var reached_max: bool = label_count >= NORMAL_MESSAGE_MAX + 1

	if reached_max:
		var child_list: Array = normal_message_container.get_children()
		var last_label: RichTextLabel = child_list.front()

		normal_message_container.remove_child(last_label)
		last_label.queue_free()
