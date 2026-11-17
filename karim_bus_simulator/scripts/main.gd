extends Node3D

const BusScript = preload("res://scripts/bus_controller.gd")
const RouteScript = preload("res://scripts/route_builder.gd")
const CITY_NAMES := ["DAR ES SALAAM", "MOROGORO", "DODOMA", "SINGIDA", "ARUSHA"]
const CITY_Z := [0.0, -450.0, -950.0, -1450.0, -2050.0]

var bus: KarimBusController
var route: KarimRouteBuilder
var chase_camera: Camera3D
var cockpit_camera: Camera3D
var hud: CanvasLayer
var speed_label: Label
var route_label: Label
var status_label: Label
var money_label: Label
var start_panel: Control
var game_panel: Control
var steering_left := false
var steering_right := false
var accelerator_down := false
var brake_down := false
var current_city_index := 0
var passengers := 0
var money := 250000.0
var satisfaction := 100.0
var distance_travelled := 0.0
var previous_position := Vector3.ZERO
var camera_mode := 0
var day_time := 0.35
var rainy := false
var _message_timer := 0.0

func _ready() -> void:
	_build_world()
	_build_ui()
	previous_position = bus.global_position
	set_process(true)

func _process(delta: float) -> void:
	if not game_panel.visible:
		return
	var steer := float(steering_right) - float(steering_left)
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer += 1.0
	var throttle := 1.0 if accelerator_down or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) else 0.0
	var brake_value := 1.0 if brake_down or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) else 0.0
	bus.set_controls(throttle, brake_value, clampf(steer, -1.0, 1.0))
	bus.handbrake = Input.is_key_pressed(KEY_SPACE)
	var moved := bus.global_position.distance_to(previous_position)
	distance_travelled += moved
	bus.fuel_litres = maxf(0.0, bus.fuel_litres - moved * 0.004)
	previous_position = bus.global_position
	day_time = fmod(day_time + delta * 0.006, 1.0)
	var sun := get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.rotation.x = lerpf(-0.15, -2.8, day_time)
		sun.light_energy = 0.15 if day_time > 0.78 or day_time < 0.18 else 1.0
	if _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0:
			status_label.text = ""
	_update_hud()
	_check_station_arrival()

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var world := Environment.new()
	world.background_mode = Environment.BG_SKY
	world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.ambient_light_color = Color(0.64, 0.72, 0.82)
	world.ambient_light_energy = 0.65
	world.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.fog_enabled = true
	world.fog_light_color = Color(0.7, 0.75, 0.72)
	world.fog_density = 0.0015
	environment.environment = world
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation = Vector3(-0.65, -0.45, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	add_child(sun)
	route = RouteScript.new()
	route.name = "TanzaniaInspiredRoute"
	add_child(route)
	bus = BusScript.new()
	bus.name = "ScaniaCoach"
	bus.position = Vector3(0.0, 0.4, 18.0)
	add_child(bus)
	chase_camera = Camera3D.new()
	chase_camera.name = "ChaseCamera"
	chase_camera.position = Vector3(0.0, 6.0, 13.0)
	chase_camera.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
	chase_camera.current = true
	bus.add_child(chase_camera)
	cockpit_camera = Camera3D.new()
	cockpit_camera.name = "RightHandDriveCockpitCamera"
	cockpit_camera.position = Vector3(0.72, 2.55, -2.7)
	cockpit_camera.current = false
	bus.add_child(cockpit_camera)

func _build_ui() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	start_panel = Control.new()
	start_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(start_panel)
	var title := Label.new()
	title.text = "KARIM BUS SIMULATOR TANZANIA"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	title.position = Vector2(70.0, 70.0)
	title.size = Vector2(900.0, 65.0)
	start_panel.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "BY KARIM GAMES STUDIO LIMITED  •  DAR ES SALAAM → ARUSHA"
	subtitle.position = Vector2(74.0, 135.0)
	subtitle.size = Vector2(900.0, 40.0)
	start_panel.add_child(subtitle)
	var start := _button("START ROUTE", Vector2(74.0, 210.0), Vector2(230.0, 62.0))
	start.pressed.connect(_start_game)
	start_panel.add_child(start)
	var note := Label.new()
	note.text = "Prototype controls: WASD / arrow keys, Space handbrake. Touch controls appear after starting."
	note.position = Vector2(74.0, 290.0)
	note.size = Vector2(800.0, 55.0)
	start_panel.add_child(note)
	game_panel = Control.new()
	game_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_panel.visible = false
	hud.add_child(game_panel)
	speed_label = _label(game_panel, "0 km/h", Vector2(22.0, 18.0), Vector2(210.0, 45.0), 26)
	route_label = _label(game_panel, "", Vector2(22.0, 62.0), Vector2(440.0, 35.0), 18)
	money_label = _label(game_panel, "", Vector2(22.0, 98.0), Vector2(330.0, 32.0), 18)
	status_label = _label(game_panel, "", Vector2(420.0, 18.0), Vector2(430.0, 55.0), 19)
	_add_hold_button("◀", Vector2(25.0, 540.0), Vector2(90.0, 90.0), "steer_left")
	_add_hold_button("▶", Vector2(125.0, 540.0), Vector2(90.0, 90.0), "steer_right")
	_add_hold_button("BRAKE", Vector2(920.0, 555.0), Vector2(115.0, 70.0), "brake")
	_add_hold_button("ACCEL", Vector2(1050.0, 525.0), Vector2(145.0, 100.0), "accelerator")
	_add_action_button("CAM", Vector2(1080.0, 20.0), Vector2(90.0, 42.0), _switch_camera)
	_add_action_button("GEAR", Vector2(975.0, 20.0), Vector2(90.0, 42.0), _shift_gear)
	_add_action_button("DOOR", Vector2(870.0, 20.0), Vector2(90.0, 42.0), _toggle_door)
	_add_action_button("BOARD", Vector2(710.0, 555.0), Vector2(120.0, 65.0), _board_passengers)
	_add_action_button("LIGHTS", Vector2(25.0, 145.0), Vector2(90.0, 42.0), _toggle_lights)
	_add_action_button("SIGNAL", Vector2(125.0, 145.0), Vector2(90.0, 42.0), _toggle_indicator)
	_add_action_button("WIPERS", Vector2(225.0, 145.0), Vector2(90.0, 42.0), _toggle_weather)
	_add_action_button("PAUSE", Vector2(1175.0, 20.0), Vector2(90.0, 42.0), _pause_game)

func _start_game() -> void:
	start_panel.visible = false
	game_panel.visible = true
	bus.freeze = false
	_status("Route started. Stop at each station to pick up passengers.")

func _button(text: String, at: Vector2, dimensions: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = dimensions
	button.add_theme_font_size_override("font_size", 20)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.16, 0.32, 0.94)
	style.border_color = Color(0.38, 0.68, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	button.add_theme_stylebox_override("normal", style)
	return button

func _label(parent: Control, text: String, at: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label

func _add_action_button(text: String, at: Vector2, dimensions: Vector2, callback: Callable) -> void:
	var button := _button(text, at, dimensions)
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(callback)
	game_panel.add_child(button)

func _add_hold_button(text: String, at: Vector2, dimensions: Vector2, action: String) -> void:
	var button := _button(text, at, dimensions)
	button.button_down.connect(_set_hold.bind(action, true))
	button.button_up.connect(_set_hold.bind(action, false))
	game_panel.add_child(button)

func _set_hold(action: String, value: bool) -> void:
	match action:
		"steer_left": steering_left = value
		"steer_right": steering_right = value
		"accelerator": accelerator_down = value
		"brake": brake_down = value

func _switch_camera() -> void:
	camera_mode = (camera_mode + 1) % 2
	chase_camera.current = camera_mode == 0
	cockpit_camera.current = camera_mode == 1

func _shift_gear() -> void:
	bus.shift_gear()
	_status("Gear: " + ("R" if bus.current_gear < 0 else str(bus.current_gear)))

func _toggle_door() -> void:
	bus.doors_open = not bus.doors_open
	_status("Left passenger door " + ("open" if bus.doors_open else "closed"))

func _toggle_lights() -> void:
	bus.set_headlights(not bus.headlights_on)

func _toggle_indicator() -> void:
	bus.left_indicator_on = not bus.left_indicator_on
	bus.right_indicator_on = not bus.left_indicator_on
	_status("Indicators " + ("on" if bus.left_indicator_on else "off"))

func _toggle_weather() -> void:
	rainy = not rainy
	var environment := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if environment and environment.environment:
		environment.environment.fog_density = 0.005 if rainy else 0.0015
		bus.linear_damp = 0.22 if rainy else 0.08
	_status("Rain " + ("enabled (reduced grip)" if rainy else "cleared"))

func _pause_game() -> void:
	get_tree().paused = not get_tree().paused
	_status("Paused" if get_tree().paused else "Resumed")

func _check_station_arrival() -> void:
	if current_city_index >= CITY_NAMES.size() - 1:
		return
	var stop_z: float = CITY_Z[current_city_index + 1]
	if absf(bus.global_position.z - stop_z) < 24.0 and absf(bus.speed_kmh) < 8.0:
		_status("Arrived at " + CITY_NAMES[current_city_index + 1] + ". Press BOARD to continue.")
		_message_timer = maxf(_message_timer, 1.0)

func _board_passengers() -> void:
	if absf(bus.speed_kmh) > 3.0:
		_status("Stop the bus before boarding.")
		return
	if current_city_index >= CITY_NAMES.size() - 1:
		_status("You completed the Dar es Salaam to Arusha route!")
		return
	var next_stop: float = CITY_Z[current_city_index + 1]
	if absf(bus.global_position.z - next_stop) > 30.0 and current_city_index > 0:
		_status("Drive to " + CITY_NAMES[current_city_index + 1] + " before boarding.")
		return
	bus.doors_open = true
	var boarded := mini(12, 48 - passengers)
	passengers += boarded
	money += boarded * 18000.0
	satisfaction = minf(100.0, satisfaction + 2.0)
	current_city_index += 1
	bus.doors_open = false
	_status("" + str(boarded) + " passengers boarded. Ticket income TZS " + str(boarded * 18000) + ".")
	if current_city_index == CITY_NAMES.size() - 1:
		_status("ARUSHA reached — route complete! Earned TZS " + str(int(money)))

func _update_hud() -> void:
	speed_label.text = str(int(absf(bus.speed_kmh))) + " km/h   " + ("R" if bus.current_gear < 0 else "D" + str(bus.current_gear))
	var destination := CITY_NAMES[mini(current_city_index + 1, CITY_NAMES.size() - 1)]
	route_label.text = "DAR ES SALAAM  →  " + destination + "     •     PASSENGERS " + str(passengers) + "/48"
	money_label.text = "TZS " + str(int(money)) + "   •   FUEL " + str(int(bus.fuel_litres)) + " L   •   SATISFACTION " + str(int(satisfaction) ) + "%"

func _status(message: String) -> void:
	status_label.text = message
	_message_timer = 4.0
