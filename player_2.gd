extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -400.0
const PUSH_FORCE := 200.0
const DAMAGE_INTERVAL := 0.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon_hitbox: Area2D = $WeaponHitbox
@onready var fireball_sound: AudioStreamPlayer2D = $FireballSound
@onready var damage_sound: AudioStreamPlayer2D = $DamageSound
@onready var health_bar: ProgressBar = $HealthBar

enum State { IDLE, MOVE, JUMP, ATTACK, BLOCK }
var current_state = State.IDLE
var last_animation: String = "mage_idle"
var health: int = 1000
var overlapping_bodies: Array = []
var damage_timer: float = 0.0
var is_being_hit: bool = false

func _ready() -> void:
	animated_sprite.play("mage_idle")
	last_animation = "mage_idle"
	health = 1000
	animated_sprite.animation_finished.connect(_on_animation_finished)
	if animated_sprite.sprite_frames:
		animated_sprite.sprite_frames.set_animation_loop("mage_jump", false)
	collision_layer = 1 << 2  # Layer 3 (editor)
	collision_mask = (1 << 0) | (1 << 1)  # Mask 1 (environment), 2 (Knight body)
	print("Mage body initialized, Layer: 3, Mask: 1, 2")
	if weapon_hitbox:
		weapon_hitbox.collision_layer = 1 << 4  # Layer 5 (editor)
		weapon_hitbox.collision_mask = 1 << 1   # Mask 2 (Knight body)
		weapon_hitbox.monitoring = false
		weapon_hitbox.monitorable = true
		weapon_hitbox.body_entered.connect(_on_weapon_hitbox_body_entered)
		weapon_hitbox.body_exited.connect(_on_weapon_hitbox_body_exited)
		print("Mage weapon hitbox initialized, Layer: 5, Mask: 2")
	else:
		print("ERROR: Mage WeaponHitbox missing")
	if not fireball_sound or not damage_sound:
		print("ERROR: Mage audio nodes missing")
	if health_bar:
		health_bar.max_value = 1000
		health_bar.value = health
		print("Mage health bar initialized, Value: ", health)
	else:
		print("WARNING: Mage HealthBar missing")

func _physics_process(delta: float) -> void:
	var direction = Input.get_axis("mage_left", "mage_right")
	var attack_held = Input.is_action_pressed("mage_attack")
	var block_held = Input.is_action_pressed("mage_block")
	var jump_pressed = Input.is_action_just_pressed("mage_jump")

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0

	if direction != 0:
		velocity.x = direction * SPEED
		animated_sprite.flip_h = direction < 0
		if weapon_hitbox:
			var shape = weapon_hitbox.get_node("WeaponCollision")
			shape.position.x = 30 if direction > 0 else -30
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if jump_pressed and is_on_floor():
		velocity.y = JUMP_VELOCITY
		current_state = State.JUMP
		animated_sprite.play("mage_jump")
		last_animation = "mage_jump"
		print("Mage jump, State: JUMP, Time: ", Time.get_ticks_msec())

	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is CharacterBody2D and collider != self:
			var push_direction = sign(position.x - collider.position.x)
			collider.velocity.x += push_direction * PUSH_FORCE
			print("Mage pushed ", collider.name, ", Force: ", push_direction * PUSH_FORCE)

	if current_state == State.ATTACK and overlapping_bodies.size() > 0:
		damage_timer += delta
		if damage_timer >= DAMAGE_INTERVAL:
			if fireball_sound:
				fireball_sound.play()
				print("Mage fireball sound, Time: ", Time.get_ticks_msec())
			for body in overlapping_bodies:
				if body is CharacterBody2D and body != self:
					if body.has_method("get_state") and body.get_state() == State.BLOCK:
						print("Mage attack blocked by ", body.name)
					elif body.has_method("take_damage"):
						body.take_damage(20)  # 200% damage
						body.set_hit_glow(true)
						print("Mage hit ", body.name, ", dealing 20 damage")
			damage_timer = 0.0

	var intended_animation = last_animation
	if is_on_floor():
		if block_held:
			current_state = State.BLOCK
			intended_animation = "mage_block"
			if weapon_hitbox:
				weapon_hitbox.monitoring = false
		elif attack_held:
			current_state = State.ATTACK
			intended_animation = "mage_attack"
			if weapon_hitbox:
				weapon_hitbox.monitoring = true
				print("Mage WeaponHitbox monitoring ON")
		elif direction != 0:
			current_state = State.MOVE
			intended_animation = "mage_move"
			if weapon_hitbox:
				weapon_hitbox.monitoring = false
		else:
			current_state = State.IDLE
			intended_animation = "mage_idle"
			if weapon_hitbox:
				weapon_hitbox.monitoring = false
	else:
		if current_state != State.JUMP:
			current_state = State.JUMP
			intended_animation = "mage_jump"
			if weapon_hitbox:
				weapon_hitbox.monitoring = false

	if animated_sprite.animation != intended_animation:
		animated_sprite.play(intended_animation)
		last_animation = intended_animation
		print("Mage State: ", State.keys()[current_state], ", Animation: ", intended_animation)

func _on_animation_finished() -> void:
	if current_state == State.JUMP and is_on_floor():
		current_state = State.IDLE
		animated_sprite.play("mage_idle")
		last_animation = "mage_idle"
		print("Mage jump finished, State: IDLE")
	elif current_state in [State.ATTACK, State.BLOCK] and is_on_floor() and not (Input.is_action_pressed("mage_attack") or Input.is_action_pressed("mage_block")):
		current_state = State.IDLE
		animated_sprite.play("mage_idle")
		last_animation = "mage_idle"
		if weapon_hitbox:
			weapon_hitbox.monitoring = false
		print("Mage Attack/Block finished, State: IDLE")

func _on_weapon_hitbox_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body != self and not overlapping_bodies.has(body):
		overlapping_bodies.append(body)
		body.set_being_hit(true)
		print("Mage WeaponHitbox entered ", body.name)

func _on_weapon_hitbox_body_exited(body: Node2D) -> void:
	if overlapping_bodies.has(body):
		overlapping_bodies.erase(body)
		if body is CharacterBody2D and body != self:
			body.set_being_hit(false)
			body.reset_color()
			print("Mage WeaponHitbox exited ", body.name)

func take_damage(amount: int) -> void:
	health -= amount
	if health_bar:
		health_bar.value = health
	animated_sprite.modulate = Color(1, 0.5, 0.5)
	if damage_sound:
		damage_sound.play()
		print("Mage damage sound, Health: ", health)
	else:
		print("ERROR: DamageSound missing")
	print("Mage took ", amount, " damage, Health: ", health)

func set_hit_glow(is_hit: bool) -> void:
	if is_hit:
		animated_sprite.modulate = Color(1, 0.5, 0.5)
		print("Mage glow set to red")
	else:
		animated_sprite.modulate = Color(1, 1, 1)
		print("Mage glow reset")

func reset_color() -> void:
	animated_sprite.modulate = Color(1, 1, 1)
	if health_bar:
		health_bar.value = health
	print("Mage color reset, Health: ", health)

func set_being_hit(is_hit: bool) -> void:
	is_being_hit = is_hit
	print("Mage is_being_hit: ", is_being_hit)

func get_state() -> int:
	return current_state
