extends Node2D

const INACTIVE_IDX = -1;
export var _isDynamicallyShowing = false
export var _listenerNodePath = ""
export var _name = ""

var ball
var bg 
var animation_player
var parent
#var listenerNode

var centerPoint = Vector2(0,0)
var currentForce = Vector2(0,0)
var halfSize = Vector2()
var ballPos = Vector2()
var squaredHalfSizeLenght = 0
var currentPointerIDX = INACTIVE_IDX;

func _ready():
	set_process_input(true)
	bg = get_node("bg")
	ball = get_node("ball")	
	animation_player = get_node("AnimationPlayer")
	parent = get_parent();
	halfSize = bg.texture.get_size() /2;
	squaredHalfSizeLenght = halfSize.x*halfSize.y;
	
	if (_listenerNodePath != "" && _listenerNodePath!=null):
		_listenerNodePath = get_node(_listenerNodePath)
	elif _listenerNodePath=="":
		_listenerNodePath = null

	_isDynamicallyShowing = _isDynamicallyShowing and parent is Control
	if _isDynamicallyShowing:
		modulate.a = 0;
#		hide()

func get_force():
	return currentForce
	
func _input(event):
	var incomingPointer = extractPointerIdx(event)
	if incomingPointer == INACTIVE_IDX:
		return
	
	if need2ChangeActivePointer(event):
		if (currentPointerIDX != incomingPointer) and event.is_pressed():
			currentPointerIDX = incomingPointer;
			showAtPos(Vector2(event.position.x, event.position.y));

	var theSamePointer = currentPointerIDX == incomingPointer
	if isActive() and theSamePointer:
		process_input(event)

func need2ChangeActivePointer(event): #touch down inside analog
	var mouseButton = event is InputEventMouseButton
	var touch = event is InputEventScreenTouch
	
	if mouseButton or touch:
		if _isDynamicallyShowing:
			return get_parent().get_global_rect().has_point(Vector2(event.position.x, event.position.y))
		else:
			var lenght = (get_global_position() - Vector2(event.position.x, event.position.y)).length_squared();
			return lenght < squaredHalfSizeLenght
	else:
	 return false

func isActive():
	return currentPointerIDX != INACTIVE_IDX

func extractPointerIdx(event):
	var touch = event is InputEventScreenTouch
	var drag = event is InputEventScreenDrag
	var mouseButton = event is InputEventMouseButton
	var mouseMove = event is InputEventMouseMotion
	
	if touch or drag:
		return event.index
	elif mouseButton or mouseMove:
		#plog("SOMETHING IS VERYWRONG??, I HAVE MOUSE ON TOUCH DEVICE")
		return 0
	else:
		return INACTIVE_IDX
		
func process_input(event):
	calculateForce(event.position.x - self.get_global_position().x, event.position.y - self.get_global_position().y)
	updateBallPos()
	
	var isReleased = isReleased(event)
	if isReleased:
		reset()


func reset():
	currentPointerIDX = INACTIVE_IDX
	calculateForce(0, 0)
	if _isDynamicallyShowing:
		hide()
	else:
		updateBallPos()

func showAtPos(pos):
	if _isDynamicallyShowing:
		animation_player.play("alpha_in", 0.2)
		self.set_global_position(pos)
	
func hide():
	animation_player.play("alpha_out", 0.2) 

func updateBallPos():
	ballPos.x = halfSize.x * currentForce.x #+ halfSize.x
	ballPos.y = halfSize.y * -currentForce.y #+ halfSize.y
	ball.set_position(ballPos)

func calculateForce(var x, var y):
	#get direction
	currentForce.x = (x - centerPoint.x)/halfSize.x
	currentForce.y = -(y - centerPoint.y)/halfSize.y
	
	#limit 
	if currentForce.length_squared()>1:
		currentForce=currentForce/currentForce.length()
	
	sendSignal2Listener()

func sendSignal2Listener():
	if (_listenerNodePath != null):
		_listenerNodePath.analog_force_change(currentForce,_name) #self)


func isPressed(event):
	if event is InputEventMouseMotion:
		return (event.button_mask==1)
	elif event is InputEventScreenTouch:
		return event.pressed

func isReleased(event):
	if event is InputEventScreenTouch:
		return !event.pressed
	elif event is InputEventMouseButton:
		return !event.pressed
	
func update_listnerNode():
	if (_listenerNodePath != "" && _listenerNodePath!=null):
		_listenerNodePath = get_node(_listenerNodePath)
	elif _listenerNodePath=="":
		_listenerNodePath = null
