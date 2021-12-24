extends Control

export var max_separation:float = 500.0
export var split_line_thickness:float = 3.0
export var split_line_color:Color = Color.black
export var adaptive_split_line_thickness:bool = true

onready var player1 = $ViewportContainer/Viewport1/Player1
onready var player2 = $ViewportContainer/Viewport1/Player2
onready var viewport1 = $ViewportContainer/Viewport1
onready var viewport2 = $ViewportContainer2/Viewport2
onready var view = $View
onready var camera1 = $ViewportContainer/Viewport1/Camera2D
onready var camera2 = $ViewportContainer2/Viewport2/Camera2D

func _ready():
	viewport2.world_2d = viewport1.world_2d
	_on_size_changed()
	_update_splitscreen()
	get_viewport().connect("size_changed", self, "_on_size_changed")

	view.material.set_shader_param("viewport1", viewport1.get_texture())
	view.material.set_shader_param("viewport2", viewport2.get_texture())


func _physics_process(delta):
	_move_cameras()
	_update_splitscreen()

func _move_cameras():
	var position_difference = _compute_position_difference_in_world()
	
	var distance = clamp(position_difference.length(), 0, max_separation)

	position_difference = position_difference.normalized() * distance

	camera1.global_position = player1.global_position + position_difference / 2.0
	camera2.global_position = player2.global_position - position_difference / 2.0

func _update_splitscreen():
	var screen_size = get_viewport().get_visible_rect().size
	
	var topLeft1 = camera1.get_camera_screen_center() - screen_size / 2.0
	var topLeft2 = camera2.get_camera_screen_center() - screen_size / 2.0
	
	var player1_position = (player1.global_position - topLeft1) / screen_size
	var player2_position = (player2.global_position - topLeft2) / screen_size
		
	var thickness
	if adaptive_split_line_thickness:
		var position_difference = _compute_position_difference_in_world()
		var distance = position_difference.length()
		thickness = lerp(0, split_line_thickness, (distance - max_separation) / max_separation)
		thickness = clamp(thickness, 0, split_line_thickness)
	else:
		thickness = split_line_thickness

	view.material.set_shader_param("split_active", _get_split_state())
	view.material.set_shader_param("player1_position", player1_position)
	view.material.set_shader_param("player2_position", player2_position)
	view.material.set_shader_param("split_line_thickness", thickness)
	view.material.set_shader_param("split_line_color", split_line_color)
	

func _get_split_state():
	var position_difference = _compute_position_difference_in_world()
	var separation_distance = position_difference.length()
	return separation_distance > max_separation
	
func _on_size_changed():
	var screen_size = get_viewport().get_visible_rect().size

	$ViewportContainer.rect_size = screen_size
	$ViewportContainer2.rect_size = screen_size
	viewport1.size = screen_size
	viewport2.size = screen_size
	view.rect_size = screen_size
	view.material.set_shader_param("viewport_size", screen_size)

func _compute_position_difference_in_world():
	return player2.global_transform.origin - player1.global_transform.origin
