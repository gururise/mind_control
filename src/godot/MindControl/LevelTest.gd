extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var testLevel : Level = get_node("level")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func runTests():
	testLevel.analog_force_change(-100,100)
	# check to see if values are within range

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
