extends RigidBody3D
class_name KarimBusController

## Simplified heavy-bus force model for the first playable prototype.
## This is not a validated real-vehicle simulation; tune against reference data before release.

@export var engine_force: float = 26000.0
@export var service_brake_force: float = 42000.0
@export var steering_torque: float = 18500.0
@export var maximum_forward_speed: float = 29.0
@export var maximum_reverse_speed: float = 5.0

var throttle: float = 0.0
var brake: float = 0.0
var steering: float = 0.0
var handbrake: bool = false
var headlights_on: bool = false
var left_indicator_on: bool = false
var right_indicator_on: bool = false
var doors_open: bool = false
var luggage_open: bool = false
var current_gear: int = 1
var fuel_litres: float = 420.0
var damage: float = 0.0
var speed_kmh: float = 0.0
var _wheel_visuals: Array[MeshInstance3D] = []
var _headlamps: Array[OmniLight3D] = []

func _ready() -> void:
	mass = 12500.0
	gravity_scale = 1.0
	linear_damp = 0.08
	angular_damp = 1.8
	can_sleep = false
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, -0.55, 0.0)
	_build_bus()

func _physics_process(_delta: float) -> void:
	var forward: Vector3 = -global_transform.basis.z
	var flat_velocity := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	speed_kmh = flat_velocity.dot(forward) * 3.6
	var drive_sign := 1.0 if current_gear >= 0 else -1.0
	if speed_kmh * drive_sign < (maximum_forward_speed if drive_sign > 0.0 else maximum_reverse_speed) * 3.6:
		apply_central_force(forward * engine_force * throttle * drive_sign)
	if brake > 0.0 or handbrake:
		var braking := service_brake_force * maxf(brake, 0.0)
		if handbrake:
			braking = service_brake_force * 0.65
		if flat_velocity.length() > 0.15:
			apply_central_force(-flat_velocity.normalized() * braking)
	# Sideways tire grip and high-center-of-mass roll stabilization.
	var lateral_velocity := global_transform.basis.x * linear_velocity.dot(global_transform.basis.x)
	apply_central_force(-lateral_velocity * (9500.0 if not handbrake else 2500.0))
	apply_torque(Vector3(0.0, steering * steering_torque * clampf(flat_velocity.length() / 4.0, 0.0, 1.0), 0.0))
	apply_torque(Vector3(-angular_velocity.x * 42000.0, 0.0, -angular_velocity.z * 52000.0))
	if flat_velocity.length() > maximum_forward_speed:
		linear_velocity = Vector3(forward.x * maximum_forward_speed, linear_velocity.y, forward.z * maximum_forward_speed)
	if fuel_litres <= 0.0:
		throttle = 0.0
	for wheel in _wheel_visuals:
		wheel.rotate_object_local(Vector3.RIGHT, speed_kmh * 0.0007)

func set_controls(accelerator: float, brake_value: float, steer_value: float) -> void:
	throttle = clampf(accelerator, 0.0, 1.0)
	brake = clampf(brake_value, 0.0, 1.0)
	steering = clampf(steer_value, -1.0, 1.0)

func shift_gear() -> void:
	current_gear += 1
	if current_gear > 5:
		current_gear = -1
	elif current_gear == 0:
		current_gear = 1

func _build_bus() -> void:
	var paint := _material(Color(0.76, 0.82, 0.87), 0.28, 0.25)
	var blue := _material(Color(0.04, 0.22, 0.48), 0.24, 0.3)
	var glass := _material(Color(0.12, 0.25, 0.32), 0.12, 0.12)
	var dark := _material(Color(0.045, 0.055, 0.065), 0.5, 0.05)
	_add_box("Chassis", Vector3(2.5, 1.05, 8.5), Vector3(0.0, 1.25, 0.0), paint)
	_add_box("Lower blue belt", Vector3(2.53, 0.42, 8.55), Vector3(0.0, 0.72, 0.0), blue)
	_add_box("Front windscreen", Vector3(2.18, 1.15, 0.08), Vector3(0.0, 2.45, -4.18), glass)
	_add_box("Rear window", Vector3(2.12, 0.85, 0.08), Vector3(0.0, 2.5, 4.28), glass)
	_add_box("Roof", Vector3(2.48, 0.18, 8.15), Vector3(0.0, 3.18, 0.0), paint)
	# Long dark window bands and visible seat rows give the prototype a readable coach silhouette.
	_add_box("Left passenger windows", Vector3(0.07, 1.05, 6.7), Vector3(-1.27, 2.45, 0.0), glass)
	_add_box("Right passenger windows", Vector3(0.07, 1.05, 6.7), Vector3(1.27, 2.45, 0.0), glass)
	_add_box("Right-hand cockpit", Vector3(0.72, 0.42, 1.25), Vector3(0.72, 1.85, -3.2), dark)
	_add_box("Left passenger door", Vector3(0.08, 2.0, 0.88), Vector3(-1.32, 1.72, -2.35), blue)
	_add_box("Luggage bay", Vector3(0.07, 0.78, 2.4), Vector3(1.3, 1.1, 0.8), dark)
	for row in range(7):
		for side in [-1.0, 1.0]:
			_add_box("Passenger seat", Vector3(0.58, 0.8, 0.58), Vector3(side * 0.57, 1.75, -1.55 + row * 0.82), blue)
	for axle_z in [-2.8, 2.8]:
		for side_x in [-1.32, 1.32]:
			var wheel := MeshInstance3D.new()
			wheel.name = "Wheel"
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.48
			cylinder.bottom_radius = 0.48
			cylinder.height = 0.28
			wheel.mesh = cylinder
			wheel.material_override = dark
			wheel.position = Vector3(side_x, 0.55, axle_z)
			wheel.rotation.z = PI / 2.0
			add_child(wheel)
			_wheel_visuals.append(wheel)
	for side_x in [-0.75, 0.75]:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(side_x, 1.75, -4.35)
		lamp.omni_range = 18.0
		lamp.light_energy = 1.5
		lamp.visible = false
		add_child(lamp)
		_headlamps.append(lamp)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.5, 2.85, 8.5)
	collision.shape = shape
	collision.position = Vector3(0.0, 1.6, 0.0)
	add_child(collision)

func _add_box(label: String, size: Vector3, at: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	visual.position = at
	add_child(visual)

func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func set_headlights(enabled: bool) -> void:
	headlights_on = enabled
	for lamp in _headlamps:
		lamp.visible = enabled
