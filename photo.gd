extends Node3D

@export var scene_id := 0

func init(texture, scene_id):
	%Sprite3D.texture = texture
	self.scene_id = scene_id
