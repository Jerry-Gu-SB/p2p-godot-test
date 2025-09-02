extends Control

var user_panel_stylebox = preload("res://lobby/theme/lobby_player_container_styleboxflat.tres")

var username_value: String

func _ready() -> void:
	var buttons = [
		%ButtonConnect,
		%ButtonDisconnect,
		%ButtonLobbyCreate,
		%ButtonLobbyLeave,
		%ButtonLobbyStart,
		%ButtonQuit
	]
	buttons.map(func(button): button.set_default_cursor_shape(Control.CURSOR_POINTING_HAND))
	
	%ButtonConnect.pressed.connect(func(): _new_user_connect())
	%ButtonDisconnect.pressed.connect(func(): LobbySystem.user_disconnect())
	%ButtonLobbyCreate.pressed.connect(func(): LobbySystem.lobby_create())
	%ButtonLobbyLeave.pressed.connect(func(): LobbySystem.lobby_leave())
	%ButtonLobbyStart.pressed.connect(func(): LobbySystem.lobby_start_game())
	%ButtonQuit.pressed.connect(func(): get_tree().quit())
	
	%InputUsername.max_length = 14
	%InputUsername.text_changed.connect(func(new_text_value): username_value = new_text_value)
	
	%ColumnLobby.hide()
	
	# Renders
	LobbySystem.signal_client_disconnected.connect(func(): _render_connection_light(false))
	LobbySystem.signal_packet_parsed.connect(func(_packet): _render_connection_light(true))
	LobbySystem.signal_lobby_list_changed.connect(_render_lobby_list)
	LobbySystem.signal_lobby_changed.connect(_render_current_lobby_view)
	LobbySystem.signal_user_list_changed.connect(_render_user_list)

	# REACTIVITY
	# Refetch user list and lobbies if anyone leaves or joins
	# (could do more precise element manipulation, but this is a shortcut)
	# TODO: Reactivity (better signals for "computed" values)
	# TODO: The server might want to automatically send these events upon the conditions. 
	LobbySystem.signal_user_joined.connect(func(_id): LobbySystem.users_get())
	LobbySystem.signal_user_left.connect(func(_id): LobbySystem.users_get();  LobbySystem.lobbies_get())
	
	# Debug
	LobbySystem.signal_packet_parsed.connect(_debug)

func _new_user_connect():
	if not username_value:
		username_value = LobbySystem.generate_random_name()
		%InputUsername.text = username_value

	LobbySystem.user_connect(username_value)

func _render_user_list(users):
	%UserList.get_children().map(func(element):  element.queue_free())

	for user in users:
		if user.has('username'):
			var user_label = Label.new()
			user_label.text = user.username
			%UserList.add_child(user_label)

# TODO: This is too involved. Rework into a preload.
func _create_user_item(username: String, color: String) -> PanelContainer:
	var user_hbox = HBoxContainer.new()
	var user_panel = PanelContainer.new()
	user_panel.add_theme_stylebox_override("panel", user_panel_stylebox)

	var rect = ColorRect.new()
	rect.custom_minimum_size = Vector2(25.0, 25.0)
	rect.color = Color.from_string(color, Color.WHITE)

	var user_label = Label.new()
	user_label.size_flags_horizontal = Control.SIZE_EXPAND
	user_label.text = username

	user_hbox.add_child(user_label)
	user_hbox.add_child(rect)
	user_panel.add_child(user_hbox)
	return user_panel

func _new_lobby_item(lobby): # Typed Dict for param here?
	var lobby_container = VBoxContainer.new()
	var lobby_label = Label.new()
	var lobby_players_label = Label.new()
	var divider = HSeparator.new()
	lobby_label.text = lobby.players[0].username + "'s Lobby"
	lobby_players_label.text = "Players: " + str(lobby.players.size())

	var	lobby_button = Button.new()
	lobby_button.set_default_cursor_shape(Control.CURSOR_POINTING_HAND)
	lobby_button.text = "Join"
	lobby_button.pressed.connect(func(): LobbySystem.lobby_join(lobby.id))

	[lobby_label, lobby_players_label, lobby_button, divider].map(lobby_container.add_child)
	
	return lobby_container

func _render_lobby_list(lobbies):
	%LobbyList.get_children().map(func(element):  element.queue_free())

	for lobby in lobbies:
		var new_lobby = _new_lobby_item(lobby)
		%LobbyList.add_child(new_lobby)
	
func _render_current_lobby_view(lobby):
	%ColumnLobby.visible = false
	%LobbyUserList.get_children().map(func(element):  element.queue_free())

	if lobby: 
		%LabelLobbyTitle.text = lobby.players[0].username + "'s Lobby"
		%ColumnLobby.visible = true
		for player in lobby.players:
			var new_color = player.metadata.get('color') if player.metadata.get('color') else '#ffffff'
			%LobbyUserList.add_child(_create_user_item(player.username, new_color))		

func _render_connection_light(is_user_connected: bool = false):
	%ConnectionLight.modulate = Color.WHITE
	if is_user_connected:	
		await get_tree().create_timer(0.08).timeout
		%ConnectionLight.modulate = Color.GREEN

func _debug(_message):
	#print('[DEBUG LOBBY PACKET]: ', _message)
	pass
