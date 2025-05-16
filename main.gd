extends Node2D

@onready var player_1 = $Player1
@onready var player_2 = $Player2
@onready var ui = $UI
@onready var network = $Network

var game_over: bool = false

func _ready() -> void:
	# Ensure players are properly set up
	if not player_1 or not player_2:
		print("ERROR: Players not found in scene")
		return
	if not ui:
		print("ERROR: UI not found in scene")
		return
	if not network:
		print("ERROR: Network not found in scene")
		return
	
	# Connect signals for game over
	player_1.take_damage = func(amount: int):
		player_1.health -= amount
		player_1.health_bar.value = player_1.health
		if player_1.health <= 0 and not game_over:
			game_over = true
			declare_winner("Player 2 (Mage)")
			network.submit_achievement("player_2_wins")
	
	player_2.take_damage = func(amount: int):
		player_2.health -= amount
		player_2.health_bar.value = player_2.health
		if player_2.health <= 0 and not game_over:
			game_over = true
			declare_winner("Player 1 (Knight)")
			network.submit_achievement("player_1_wins")

	# Initialize UI
	ui.update_status("Game Started!")

func _process(delta: float) -> void:
	if game_over:
		return
	# Update UI with health
	ui.update_health(player_1.health, player_2.health)

func declare_winner(winner: String) -> void:
	ui.update_status(winner + " Wins!")
	# Optionally, stop player inputs here or transition to a game over screen
