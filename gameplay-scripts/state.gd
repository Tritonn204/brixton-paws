extends Node2D

class_name PlayerState

func enter(host):pass
func exit(host):pass

func step(host, delta: float):pass

func get_class(): return "PlayerState"
func is_class(name:String): return get_class() == name || .is_class(name)

func draw(host):pass
