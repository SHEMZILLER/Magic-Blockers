extends Control

@onready var wallet_login_button = $WalletLoginButton
@onready var wallet_status_label = $WalletStatusLabel
@onready var match_selection = $MatchSelection
@onready var leaderboard = $Leaderboard
@onready var refresh_button = $RefreshButton
@onready var network = get_node("/root/MagicBlockers/Network")

# Child nodes of MatchSelection (VBoxContainer)
@onready var host_button = $MatchSelection/HostButton
@onready var join_button = $MatchSelection/JoinButton
@onready var address_input = $MatchSelection/AddressInput

func _ready() -> void:
	# Connect signals for wallet login and refresh
	wallet_login_button.pressed.connect(_on_wallet_login_button_pressed)
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	
	# Connect signals for host and join buttons
	if host_button:
		host_button.pressed.connect(_on_host_button_pressed)
	else:
		print("ERROR: HostButton not found in MatchSelection")
	if join_button:
		join_button.pressed.connect(_on_join_button_pressed)
	else:
		print("ERROR: JoinButton not found in MatchSelection")
	if not address_input:
		print("ERROR: AddressInput not found in MatchSelection")
	
	# Initialize UI
	wallet_status_label.text = "Wallet Disconnected"
	if leaderboard:
		leaderboard.clear()  # Clear any existing items
		leaderboard.add_item("Leaderboard: N/A")  # Add initial message
	else:
		print("ERROR: Leaderboard node not found")
	if address_input:
		address_input.text = ""

func _on_wallet_login_button_pressed() -> void:
	if network.solana_client.authenticate(network.player_address):
		wallet_status_label.text = "Wallet Connected: " + network.player_address
	else:
		wallet_status_label.text = "Wallet Connection Failed"

func _on_refresh_button_pressed() -> void:
	network.update_rankings()
	if leaderboard:
		# For now, just add a placeholder message
		# In a real implementation, you'd populate the leaderboard with actual rankings
		leaderboard.clear()
		leaderboard.add_item("Leaderboard: Updated")
	else:
		print("ERROR: Leaderboard node not found")

func _on_host_button_pressed() -> void:
	var address = address_input.text if address_input else ""
	if address == "":
		wallet_status_label.text = "Please enter an address to host"
		return
	wallet_status_label.text = "Hosting match at address: " + address
	print("Hosting match at address: ", address)

func _on_join_button_pressed() -> void:
	var address = address_input.text if address_input else ""
	if address == "":
		wallet_status_label.text = "Please enter an address to join"
		return
	wallet_status_label.text = "Joining match at address: " + address
	print("Joining match at address: ", address)

func update_status(message: String) -> void:
	wallet_status_label.text = message

func update_health(player_1_health: int, player_2_health: int) -> void:
	pass
