class_name Map extends Node2D

# Map contains TileMaps which are drawn in the world. Note
# that some tiles are background while other tiles may be
# drawn in front of units depending on their position. Map
# also contains extra non-visual map nodes which are used
# for gameplay purposes.
# 
# MainTileMap is for tiles which are aligned with the tile
# grid (256x128). Contains things like floors and walls.
# 
# DecorationTileMap is for tiles which need to have more
# free positioning. This TileMap has a smaller grid size
# (64x32). Contains things like vegetation, barrels, etc.

# NOTE: explanation of z_index values for tilemap layers and units:
# - 0 = lvl1-flat tilemap layer, this is for floor tiles on
#   lvl1 elevation
# - 10 = lvl1-tall tilemap layer, this is for tall tiles
#   (walls) on lvl1 elevation
# - 10 = lvl2-flat tilemap layer, this is for floor tiles on
#   lvl2 elevation
# - 20 = lvl2-tall tilemap layer, this is for tall tiles
#   (walls) on lvl2 elevation
#
# Buildable area tiles have z_index of 12, so that they are:
# - above lvl2 flat tiles
# - above lvl2 flat decoration tiles
# - below lvl2 units and tall tiles
#
# Note that lvl2-flat layer has same z_index as lvl1-tall
# but it has y-sort origin of 192. This effectively makes
# the floor tiles placed on lvl2-flat act the same as
# lvl1-tall tiles. Imagine it as a transparent cube with a
# floor tile on top. Making lvl2-flat have z_index of 20
# would not work because lvl2 floor tiles would draw
# over tall decorations like trees, placed on lvl1.
# 
# For decoration tilemap, the z_indexes is similar, but for
# flat layers, the z_index is +1 greater than tilemap flat
# layers. This is so that flat decorations like vines are
# always drawn above tilemap flat tiles. For example:
# - 0 = lvl1-flat tilemap layer
# - 1 = lvl1-flat decoration layer
# 
# Ground creeps have z_index of 10, so that they are:
# - above lvl1 flat tiles
# - y-sorted with lvl1 tall tiles and lvl2 flat tiles
# - below lvl2 tall tiles
# 
# Ground creeps can be temporarily elevated with tower
# abilities. In such cases, their z_index gains a +10 and
# becomes 20. Elevated creeps are:
# - above all lvl1 tiles
# - above lvl2 flat tiles
# - y-sorted with lvl2 tall tiles
# 
# Air creeps have z_index of 21, so that they are:
# - above all tilemap and decoration tiles
# - above temporarily elevated creeps
# - above towers
# 
# Towers have z_index of 20, so that they are:
# - above lvl2 flat tiles
# - y-sorted with lvl2 tall tiles
# - below air creeps
# 
# Corpses have z_index of 10, so that they are:
# - above lvl1 flat tiles
# - above lvl1 decoration flat tiles
# - y-sorted with lvl1 tall tiles


@export var _camera_limits: Polygon2D
@export var _buildable_area: TileMap
@export var _ground_indicator_map: TileMap

const BUILDABLE_PULSE_ALPHA_MIN = 0.1
const BUILDABLE_PULSE_ALPHA_MAX = 0.5
const BUILDABLE_PULSE_PERIOD = 1.0


#########################
###     Built-in      ###
#########################

func _ready():
	var camera: Camera2D = get_viewport().get_camera_2d()
	var camera_limits_rect: Rect2 = Utils.get_polygon_bounding_box(_camera_limits)
	camera.limit_bottom = int(camera_limits_rect.end.y)
	camera.limit_top = int(camera_limits_rect.position.y)
	camera.limit_left = int(camera_limits_rect.position.x)
	camera.limit_right = int(camera_limits_rect.end.x)
	
	print_verbose("Set camera limits to [bottom: %s, top: %s, left: %s, right: %s]" % [camera.limit_bottom, camera.limit_top, camera.limit_left, camera.limit_right])
	
#	Make buildable area pulse by tweening it's alpha between
#	min and max
	var buildable_area_tween = create_tween()
	buildable_area_tween.tween_property(_buildable_area, "modulate",
		Color(1.0, 1.0, 1.0, BUILDABLE_PULSE_ALPHA_MIN),
		0.5 * BUILDABLE_PULSE_PERIOD).set_trans(Tween.TRANS_LINEAR)
	buildable_area_tween.tween_property(_buildable_area, "modulate",
		Color(1.0, 1.0, 1.0, BUILDABLE_PULSE_ALPHA_MAX),
		0.5 * BUILDABLE_PULSE_PERIOD).set_trans(Tween.TRANS_LINEAR).set_delay(0.5 * BUILDABLE_PULSE_PERIOD)
	buildable_area_tween.set_loops()


#########################
###       Public      ###
#########################

func get_buildable_cells() -> Array[Vector2i]:
	var buildable_cells: Array[Vector2i] = _buildable_area.get_used_cells(0)

	return buildable_cells


func pos_is_on_ground(pos: Vector2) -> bool:
	var map_pos = _ground_indicator_map.local_to_map(pos)
	var tile_data_at_pos: TileData = _ground_indicator_map.get_cell_tile_data(0, map_pos)
	var tile_exists: bool = tile_data_at_pos != null

	return tile_exists


func set_buildable_area_visible(value: bool):
	_buildable_area.visible = value
