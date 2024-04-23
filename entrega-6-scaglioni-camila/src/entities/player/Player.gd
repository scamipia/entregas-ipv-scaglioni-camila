extends KinematicBody2D

## El uso de "%path" es un shorthand para acceder a los "Nodos Unicos de Escena"
## El nodo "Weapon" está marcado como un "Nodo Único de Escena", es decir, es el
## único nodo en la escena actual que se llama así, por lo que si se hace una query del
## mismo utilizando este patrón, se puede acceder a él de manera dinámica sin
## importar su ubicación en el árbol, es decir, ya no se tiene que especificar una
## ruta estática al mismo.
## https://docs.godotengine.org/es/stable/tutorials/scripting/scene_unique_nodes.html
onready var weapon: Node = $"%Weapon"
onready var body_animations: AnimationPlayer = $BodyAnimations
onready var body_pivot: Node2D = $BodyPivot


const FLOOR_NORMAL: Vector2 = Vector2.UP  # Igual a Vector2(0, -1)
const SNAP_DIRECTION: Vector2 = Vector2.UP
const SNAP_LENGHT: float = 32.0
const SLOPE_THRESHOLD: float = deg2rad(46)

export (float) var ACCELERATION: float = 60.0
export (float) var H_SPEED_LIMIT: float = 600.0
export (int) var jump_speed: int = 500
export (float) var FRICTION_WEIGHT: float = 0.1
export (int) var gravity: int = 10

var projectile_container: Node

var velocity: Vector2 = Vector2.ZERO
var snap_vector: Vector2 = SNAP_DIRECTION * SNAP_LENGHT

## Flag de ayuda para saber identificar el estado de actividad
var dead: bool = false


func _ready() -> void:
	initialize()


func initialize(projectile_container: Node = get_parent()) -> void:
	self.projectile_container = projectile_container
	weapon.projectile_container = projectile_container

func _process_input() -> void:
	## Estoy muerto, asi que dejo de procesar inputs y solo aplico fricción para
	## que no se deslice como cubito de hielo
	if dead:
		velocity.x = lerp(velocity.x, 0, FRICTION_WEIGHT) if abs(velocity.x) > 1 else 0
		return
	
	# Weapon Fire
	if Input.is_action_just_pressed("fire_cannon"):
		if projectile_container == null:
			projectile_container = get_parent()
		if weapon.projectile_container == null:
			weapon.projectile_container = projectile_container
		weapon.fire()

	# Jump Action
	var jump = Input.is_action_just_pressed("jump")
	if jump and is_on_floor():
		velocity.y -= jump_speed

	#Horizontal Movement
	var h_movement_direction: int = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	if h_movement_direction != 0:
		velocity.x = clamp(velocity.x + (h_movement_direction * ACCELERATION), -H_SPEED_LIMIT, H_SPEED_LIMIT)
		body_pivot.scale.x = 1 - 2 * float(h_movement_direction < 0)
	else:
		velocity.x = lerp(velocity.x, 0, FRICTION_WEIGHT) if abs(velocity.x) > 1 else 0
	
	if !is_on_floor():
		_play_animation("Jump")
	elif h_movement_direction != 0:
		_play_animation("Walk")
	else:
		_play_animation("Idle")
	
	weapon.process_input()


func _physics_process(delta: float) -> void:
	_process_input()
	velocity.y += gravity
	velocity = move_and_slide_with_snap(velocity, snap_vector, FLOOR_NORMAL, true, 4, SLOPE_THRESHOLD)


func notify_hit() -> void:
	print("I'm player and imma die")
	call_deferred("_remove")


func _remove() -> void:
	set_physics_process(false)
	hide()
	collision_layer = 0


## Wrapper sobre el llamado a animación para tener un solo punto de entrada controlable
## (en el caso de que necesitemos expandir la lógica o debuggear, por ejemplo)
func _play_animation(animation: String) -> void:
	if body_animations.has_animation(animation):
		body_animations.play(animation)
