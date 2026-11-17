extends Node3D
class_name KarimRouteBuilder

## Procedurally assembled, low-poly Tanzania-inspired highway test route.
## Replace generated geometry with licensed authored assets for a production map.

const ROUTE_NAMES := ["DAR ES SALAAM", "MOROGORO", "DODOMA", "SINGIDA", "ARUSHA"]
const ROUTE_Z := [0.0, -450.0, -950.0, -1450.0, -2050.0]

func _ready() -> void:
	build_route()

func build_route() -> void:
	var grass := _mat(Color(0.31, 0.43, 0.21), 0.95)
	var asphalt := _mat(Color(0.12, 0.14, 0.15), 0.94)
	var shoulder := _mat(Color(0.53, 0.43, 0.28), 1.0)
	var white := _mat(Color(0.9, 0.88, 0.72), 0.7)
	var road_body := StaticBody3D.new()
	road_body.name = "Highway collision"
	var road_shape := CollisionShape3D.new()
	var road_box := BoxShape3D.new()
	road_box.size = Vector3(15.0, 0.3, 2300.0)
	road_shape.shape = road_box
	road_shape.position = Vector3(0.0, 0.0, -1030.0)
	road_body.add_child(road_shape)
	add_child(road_body)
	_add_box("Tanzania savanna", Vector3(1400.0, 0.5, 2600.0), Vector3(0.0, -0.45, -1030.0), grass)
	_add_box("Highway", Vector3(15.0, 0.22, 2300.0), Vector3(0.0, -0.05, -1030.0), asphalt)
	_add_box("Left shoulder", Vector3(2.5, 0.24, 2300.0), Vector3(-8.75, -0.04, -1030.0), shoulder)
	_add_box("Right shoulder", Vector3(2.5, 0.24, 2300.0), Vector3(8.75, -0.04, -1030.0), shoulder)
	for z in range(-2180, 100, 36):
		_add_box("Centre road marking", Vector3(0.16, 0.03, 17.0), Vector3(0.0, 0.085, float(z)), white)
	for index in ROUTE_NAMES.size():
		var station := Node3D.new()
		station.name = ROUTE_NAMES[index].capitalize() + " Bus Station"
		station.position = Vector3(14.0, 0.0, ROUTE_Z[index])
		add_child(station)
		_add_box("Station shelter", Vector3(8.0, 0.3, 5.0), station.position + Vector3(0.0, 2.8, 0.0), _mat(Color(0.04, 0.22, 0.48), 0.5))
		_add_box("Station floor", Vector3(10.0, 0.2, 8.0), station.position + Vector3(0.0, 0.05, 0.0), shoulder)
		var sign := Label3D.new()
		sign.text = ROUTE_NAMES[index]
		sign.font_size = 48
		sign.pixel_size = 0.015
		sign.position = station.position + Vector3(0.0, 4.0, -3.0)
		sign.rotation.y = PI
		add_child(sign)
	for z in range(-2150, 50, 95):
		for side in [-1.0, 1.0]:
			var x := side * randf_range(24.0, 70.0)
			_add_tree(Vector3(x, 0.0, float(z) + randf_range(-22.0, 22.0)))
	for index in 50:
		var z := randf_range(-1950.0, -100.0)
		var x := (1.0 if index % 2 == 0 else -1.0) * randf_range(28.0, 90.0)
		var color := [Color(0.67, 0.49, 0.28), Color(0.72, 0.66, 0.48), Color(0.49, 0.28, 0.19)][index % 3]
		_add_box("Roadside shop", Vector3(randf_range(4.0, 8.0), randf_range(2.5, 4.0), 5.0), Vector3(x, 1.5, z), _mat(color, 0.9))

func _add_tree(at: Vector3) -> void:
	var trunk := _mat(Color(0.28, 0.18, 0.1), 0.95)
	var leaves := _mat(Color(0.16, 0.33, 0.13), 0.9)
	_add_cylinder("Tree trunk", 0.28, 4.2, at + Vector3(0.0, 2.1, 0.0), trunk)
	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = randf_range(1.8, 3.0)
	sphere.height = sphere.radius * 1.9
	crown.mesh = sphere
	crown.material_override = leaves
	crown.position = at + Vector3(0.0, 4.7, 0.0)
	add_child(crown)

func _add_box(label: String, size: Vector3, at: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.position = at
	add_child(node)

func _add_cylinder(label: String, radius: float, height: float, at: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	node.mesh = mesh
	node.material_override = material
	node.position = at
	add_child(node)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
