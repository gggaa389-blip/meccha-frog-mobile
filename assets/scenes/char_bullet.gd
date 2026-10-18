extends Area3D


@export var damage: int = 5
@export var speed: int = 5



func _ready() -> void:
	top_level = true

func _process(delta: float) -> void:
	translate_object_local(Vector3.FORWARD * speed * delta)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.get_parent().pid == 1:
		body.get_parent().hurt(damage)
	call_deferred("queue_free")


func _on_timer_timeout() -> void:
	call_deferred("queue_free")
