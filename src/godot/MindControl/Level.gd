extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var player_GDscript : KinematicBody2D = get_node("player_GDscript")
onready var textEdit : TextEdit = get_node("Button/TextEdit")
onready var greenButton : Sprite = get_node("green_button")
onready var redButton : Sprite = get_node("red_button")
onready var statusText : TextEdit = get_node("StatusLabel/TextEdit")
onready var richLabel : RichTextLabel = get_node("CanvasLayer/RichTextLabel")

var server_address : String = "192.168.1.205"
var server_port : int = 10000
var socketUDP = PacketPeerUDP.new()
var velocity : Vector2 = Vector2()
var lastForce : Vector2 = Vector2()
var ready_to_fire : bool = true
var powerLevel : int = 100
var debug : bool = false
#var _dir = Vector2(0,0)


# Called when the node enters the scene tree for the first time.
func _ready():
	player_GDscript.Play_Scale_Animation()
	textEdit.select_all()
	textEdit.cut()
	textEdit.insert_text_at_cursor(server_address + ":")
	textEdit.insert_text_at_cursor(str(server_port))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if socketUDP.get_available_packet_count() > 0:
		var array_bytes = socketUDP.get_packet()
		statusText.insert_text_at_cursor(array_bytes.get_string_from_ascii()+"\n")
		#printt("msg server: " + array_bytes.get_string_from_ascii())
#	pass

func _connect_to_udp():
	if(socketUDP.listen(server_port,"10000") != OK):
		print_debug("Error listening on port: " + str(server_port) + " in server: " + server_address)
	else:
		print_debug("Listening on port: " + str(server_port) + " in server: " + server_address)
	if (socketUDP.set_dest_address(server_address, server_port) != OK):
		redButton.visible = true
		greenButton.visible = false
	else:
		redButton.visible = false
		greenButton.visible = true

func _on_Button_pressed():
	var strArray = textEdit.get_line(0).split(":",true,1)
	server_address = strArray[0]
	server_port = int(strArray[1])
	_connect_to_udp()
	
func analog_force_change(inForce, inAnalog):
	player_GDscript._dir = Vector2(2,inForce.x)
	if abs(inForce.x) == 0:
		send_zero()
	else:
		if (abs(inForce.y-lastForce.y) > 0.1 or abs(inForce.x-lastForce.x) > 0.1):
			var pac = "Y".to_ascii() + str(stepify(inForce.y*powerLevel,1.0)).to_ascii() + ":X".to_ascii() + str(stepify(inForce.x*powerLevel,1.0)).to_ascii()
			socketUDP.put_packet(pac)
			lastForce = inForce
			if (debug):
				statusText.insert_text_at_cursor("Sent X: " + str(stepify(inForce.x*powerLevel,1.0))+"\n")
				statusText.cursor_set_line(statusText.get_line_count())
			print_debug(str(stepify(inForce.x*powerLevel,1.0)))

#func _input(event):
#	var horizontal = event.get_action_strength("right") - event.get_action_strength("left")
#	var vertical = event.get_action_strength("up") - event.get_action_strength("down")
#	var pac = "Y".to_ascii() + str(vertical*100).to_ascii() + ":X".to_ascii() + str(horizontal*100).to_ascii()
#	socketUDP.put_packet(pac)	
	#print_debug("horiz: " + str(horizontal))
	

func send_zero():
	var pac = "Y".to_ascii() + str(0).to_ascii() + ":X".to_ascii() + str(0).to_ascii()
	socketUDP.put_packet(pac)
	if (debug):
		statusText.insert_text_at_cursor("Sent X: 0\n")
		statusText.cursor_set_line(statusText.get_line_count())

func _on_Button2_pressed():
	send_zero()
	statusText.insert_text_at_cursor("Force x and y to ZERO\n")
	
func _on_Button3_pressed():
	if (ready_to_fire == true):
		ready_to_fire = false
		player_GDscript.Play_Anim()
		$Timer.start()
		socketUDP.put_packet("T2".to_ascii())

func _on_Button4_pressed():
	if (ready_to_fire == true):
		ready_to_fire = false
		player_GDscript.Play_Anim()
		$Timer.start()
		socketUDP.put_packet("T3".to_ascii())

func _on_DebugButton_pressed():
	debug = !debug

func _on_Timer_timeout():
	ready_to_fire = true
	player_GDscript.Stop_Anim()

func _on_ClearButton_pressed():
	statusText.set("text","")


func _on_VSlider_value_changed(value):
	richLabel.clear()
	richLabel.add_text(str(value))
	powerLevel = int(value)


func _on_DebugButton2_pressed():
	socketUDP.put_packet("D".to_ascii())
	print_debug("DEBUG UDP : D")
