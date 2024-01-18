extends Node2D
class_name Character

export var character_values : Resource
onready var msm = $"../../MSM"
#onready var attack_box : Node2D = $AttackBoxes
onready var current_attack_shape : CollisionShape2D

var is_rolling : bool = false

func erase_state():pass

func on_player_load_me(player):
	set_owner(player)
	msm.character_ready(self)
	set_process(true)
