extends Node

func _ready():
	$Player.set_projectile_container(self)
	$Turret.set_values($Player,self)
