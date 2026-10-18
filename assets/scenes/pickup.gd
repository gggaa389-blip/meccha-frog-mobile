extends Node3D



func _process(delta: float) -> void:
	rotate_y(deg_to_rad(90.0) * delta)


func _on_area_3d_body_entered(body: Node3D) -> void:
	var body_owner: Node3D = body.get_parent() #The Giraffe shouldn't be able to pick up these
	if not body.is_in_group("player"): return 
	if body_owner.pid == 1: return
	if is_in_group("gun"):
		if body_owner.has_gun: return
		body_owner.has_gun = true
	elif is_in_group("heal"): 
		body_owner.heals += 1
	elif is_in_group("key"):
		if body_owner.keys >= 1: return
		body_owner.keys += 1
	elif is_in_group("revive"):
		if body_owner.has_soda: return
		body_owner.has_soda = true
	elif is_in_group("talkie"): 
		if body_owner.has_talkie: return
		body_owner.has_talkie = true
	
	#$Area3D/CollisionShape3D.call_deferred("disabled", true)
	$Area3D.queue_free()
	hide()
	$PickupAudio.play()
	await $PickupAudio.finished
	queue_free()
