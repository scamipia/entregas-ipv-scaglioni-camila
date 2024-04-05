extends Sprite

class_name Projectile

var direction:Vector2

func _ready():
	set_physics_process(false)
	
func set_starting_values(starting_position:Vector2, direction2:Vector2):
	global_position = starting_position
	self.direction = direction2
	set_physics_process(true)
	
func _physics_process(delta):
	position += self.direction * 50 * delta
	
