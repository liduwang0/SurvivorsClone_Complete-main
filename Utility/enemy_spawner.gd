extends Node2D

@export var spawns: Array[Spawn_info] = []

# 性能优化设置
@export var enable_optimization: bool = true  # 是否启用优化
@export var max_enemies: int = 200  # 最大敌人数量限制
@export var max_enemies_per_spawn: int = 30  # 每次生成的最大敌人数量
@export var culling_distance: float = 2000.0  # 超过此距离的敌人会被清除
@export var check_culling_interval: int = 5  # 每隔多少秒检查一次清理

@onready var player = get_tree().get_first_node_in_group("player")
@onready var flow_field = get_node_or_null("../FlowField")

@export var time = 0

var enemy_count = 0  # 当前敌人数量
var culling_timer = 0  # 清理计时器

signal changetime(time)

func _ready():
	connect("changetime",Callable(player,"change_time"))
	
	# 设置流场的目标（玩家）
	if flow_field:
		flow_field.set_target(player)

func _process(delta):
	# 定期检查是否需要清理远处的敌人
	if enable_optimization:
		culling_timer += delta
		if culling_timer >= check_culling_interval:
			culling_timer = 0
			cull_distant_enemies()

func _on_timer_timeout():
	time += 1
	var enemy_spawns = spawns
	
	# 统计当前敌人数量
	if enable_optimization:
		enemy_count = get_tree().get_nodes_in_group("enemy").size()
		
		# 如果敌人数量已达到上限，则不再生成
		if enemy_count >= max_enemies:
			emit_signal("changetime", time)
			return
	
	for i in enemy_spawns:
		if time >= i.time_start and time <= i.time_end:
			if i.spawn_delay_counter < i.enemy_spawn_delay:
				i.spawn_delay_counter += 1
			else:
				i.spawn_delay_counter = 0
				var new_enemy = i.enemy
				var counter = 0
				
				# 计算本次实际要生成的敌人数量
				var spawn_count = i.enemy_num
				if enable_optimization:
					# 确保不超过每次生成上限
					spawn_count = min(spawn_count, max_enemies_per_spawn)
					# 确保不超过总体上限
					spawn_count = min(spawn_count, max_enemies - enemy_count)
					# 如果没有空间生成敌人，直接跳过
					if spawn_count <= 0:
						continue
				
				while counter < spawn_count:
					var enemy_spawn = new_enemy.instantiate()
					enemy_spawn.global_position = get_random_position()
					
					# 如果敌人支持流场寻路，并且Spawn_info配置了使用流场
					if i.use_flow_field and "use_flow_field" in enemy_spawn:
						enemy_spawn.use_flow_field = true
					
					# 如果启用了优化，配置敌人的优化设置
					if enable_optimization and "enable_optimization" in enemy_spawn:
						enemy_spawn.enable_optimization = true
						
						# 根据当前敌人总数调整优化参数
						if enemy_count > 150:
							# 非常多敌人时使用更激进的优化
							enemy_spawn.medium_distance = 600.0
							enemy_spawn.far_distance = 1000.0
							enemy_spawn.medium_update_frames = 4
							enemy_spawn.far_update_frames = 8
						elif enemy_count > 80:
							# 较多敌人时的中等优化
							enemy_spawn.medium_distance = 700.0
							enemy_spawn.far_distance = 1200.0
							enemy_spawn.medium_update_frames = 3
							enemy_spawn.far_update_frames = 6
					
					# 将敌人添加到"enemy"组以便于管理
					if !enemy_spawn.is_in_group("enemy"):
						enemy_spawn.add_to_group("enemy")
					
					add_child(enemy_spawn)
					counter += 1
					enemy_count += 1
					
	emit_signal("changetime", time)

# 清理远离玩家的敌人
func cull_distant_enemies():
	if player == null:
		return
		
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.global_position.distance_to(player.global_position) > culling_distance:
			# 如果敌人有自定义移除信号，触发它
			if enemy.has_signal("remove_from_array"):
				enemy.emit_signal("remove_from_array", enemy)
			# 移除敌人
			enemy.queue_free()
			enemy_count -= 1

func get_random_position():
	var vpr = get_viewport_rect().size * randf_range(1.1,1.4)
	var top_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y - vpr.y/2)
	var top_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y - vpr.y/2)
	var bottom_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y + vpr.y/2)
	var bottom_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y + vpr.y/2)
	var pos_side = ["up","down","right","left"].pick_random()
	var spawn_pos1 = Vector2.ZERO
	var spawn_pos2 = Vector2.ZERO
	
	match pos_side:
		"up":
			spawn_pos1 = top_left
			spawn_pos2 = top_right
		"down":
			spawn_pos1 = bottom_left
			spawn_pos2 = bottom_right
		"right":
			spawn_pos1 = top_right
			spawn_pos2 = bottom_right
		"left":
			spawn_pos1 = top_left
			spawn_pos2 = bottom_left
	
	var x_spawn = randf_range(spawn_pos1.x, spawn_pos2.x)
	var y_spawn = randf_range(spawn_pos1.y,spawn_pos2.y)
	return Vector2(x_spawn,y_spawn)
