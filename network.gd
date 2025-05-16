extends Node

# Reference to the SolanaClient node (add this node in the scene tree)
@onready var solana_client = $SolanaClient  # Ensure you add a SolanaClient node in the scene
var player_address: String = "PLAYER_WALLET_ADDRESS"  # Replace with actual wallet address
var game_program_id: String = "MAGICBLOCK_PROGRAM_ID"  # Replace with MagicBlock's program ID

func _ready() -> void:
	# Initialize Solana connection
	if solana_client:
		# Set the cluster (e.g., devnet)
		solana_client.set_cluster("devnet")  # Adjust based on SDK documentation
		
		# Check connection by fetching the cluster version
		var version = solana_client.get_version()
		if version != null:
			print("Connected to Solana network, version: ", version)
		else:
			print("ERROR: Failed to connect to Solana network")
		
		# Authenticate player (simplified)
		if solana_client.authenticate(player_address):
			print("Player authenticated: ", player_address)
		else:
			print("ERROR: Player authentication failed")
	else:
		print("ERROR: SolanaClient node not found")

func submit_achievement(achievement_id: String) -> void:
	if not solana_client:
		print("ERROR: SolanaClient not available")
		return
	
	# Submit achievement to MagicBlock's on-chain system
	var transaction = solana_client.create_transaction(player_address, game_program_id)
	transaction.add_instruction("submit_achievement", {"achievement_id": achievement_id})
	
	if solana_client.send_transaction(transaction):
		print("Achievement submitted: ", achievement_id)
		update_rankings()
	else:
		print("ERROR: Failed to submit achievement: ", achievement_id)

func update_rankings() -> void:
	if not solana_client:
		print("ERROR: SolanaClient not available")
		return
	
	# Fetch and update rankings (simplified)
	var rankings = solana_client.fetch_rankings(game_program_id)
	if rankings:
		print("Rankings updated: ", rankings)
	else:
		print("ERROR: Failed to fetch rankings")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Clean up Solana connection on exit
		if solana_client:
			solana_client.disconnect_from_network()
