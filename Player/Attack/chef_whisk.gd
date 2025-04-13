extends Area2D

# 基本属性
var level = 1
var damage = 1  # 基础伤害，会根据从player_test.gd传递的等级被覆盖
var shoot_distance = 150  # 增加射程距离，让随机方向更明显
var damage_tick = 1.0  # 每秒造成伤害的次数
var pull_force = 20    # 基础吸引力，会根据从player_test.gd传递的等级被覆盖

# 状态变量
var enemies_in_area = []
var direction = Vector2.ZERO
var target_position = Vector2.ZERO
var debug_damage_count = 0
var is_active = false  # 是否已经激活
var is_flying = true    # 是否正在飞行中

# 从player_test.gd传递的属性
var vortex_radius = 50  # 默认值
var vortex_duration = 3.0  # 默认值

# 信号
signal hit_enemy(enemy, damage)

func _ready():
	# 先打印一下传入值，便于调试
	print("[打蛋器] 初始化 - 持续时间:", vortex_duration, " 半径:", vortex_radius)
	
	# 获取玩家方向并计算目标位置
	get_player_direction()
	target_position = global_position + direction * shoot_distance
	
	# 设置碰撞
	collision_layer = 4  # 攻击层
	collision_mask = 2   # 敌人层
	
	# 根据level设置属性 - 伤害和吸引力将根据等级增加
	# 伤害值已在spawn_chef_whisk_vortex中设置，这里不再覆盖
	# pull_force已在spawn_chef_whisk_vortex中设置，这里不再覆盖
	# 之前的方式会忽略配置中的参数：
	# damage = level * 1.0
	# pull_force = 20 + level * 20
	# 保持pull_force不变，使用从玩家传入的值
	
	# 设置碰撞形状半径
	$CollisionShape2D.shape.radius = vortex_radius
	
	# 确保打蛋器是完全可见的
	modulate.a = 1.0
	
	# 关闭碰撞检测，避免飞行时触发碰撞
	$CollisionShape2D.disabled = true
	
	# 处理持续时间 - 长时间效果需要特殊处理
	var is_long_duration = vortex_duration > 10.0
	var animation_duration = 5.0  # 标准动画长度

	# 对于超长持续时间，使用自定义计时器而不是依赖动画长度
	if is_long_duration:
		print("[打蛋器] 检测到长时间效果:", vortex_duration, "秒，使用额外计时器")
		
		# 创建一个延迟删除的额外计时器
		var delete_timer = Timer.new()
		delete_timer.name = "DeleteTimer"
		delete_timer.wait_time = vortex_duration
		delete_timer.one_shot = true
		delete_timer.autostart = false
		add_child(delete_timer)
		
		# 连接信号
		delete_timer.timeout.connect(self.prepare_for_deletion)
		
		# 使用动画的标准长度，但不会在动画结束时销毁
		if $AnimationPlayer.has_animation("vortex"):
			var anim = $AnimationPlayer.get_animation("vortex")
			
			# 设置标准动画长度
			anim.length = animation_duration
			
			# 清除任何queue_free调用，因为我们使用计时器来控制销毁
			for i in range(anim.get_track_count()):
				if anim.track_get_type(i) == Animation.TYPE_METHOD:
					for k in range(anim.track_get_key_count(i) - 1, -1, -1):
						var key_value = anim.track_get_key_value(i, k)
						if key_value.method == "queue_free" or key_value.method == "prepare_for_deletion":
							anim.track_remove_key(i, k)
			
			# 修改动画使其循环播放
			$AnimationPlayer.get_animation("vortex").loop_mode = Animation.LOOP_LINEAR
	else:
		# 普通持续时间直接使用动画长度
		if $AnimationPlayer.has_animation("vortex"):
			var anim = $AnimationPlayer.get_animation("vortex")
			anim.length = vortex_duration
			
			# 修复动画中的方法调用时间点，使其与持续时间匹配
			var found_queue_free = false
			var method_track_index = -1
			
			# 找到方法轨道
			for i in range(anim.get_track_count()):
				if anim.track_get_type(i) == Animation.TYPE_METHOD:
					method_track_index = i
					# 检查现有的键
					for k in range(anim.track_get_key_count(i)):
						var key_time = anim.track_get_key_time(i, k)
						var key_value = anim.track_get_key_value(i, k)
						if key_value.method == "queue_free":
							# 将queue_free方法的调用时间更新为持续时间末尾
							anim.track_set_key_time(i, k, vortex_duration)
							found_queue_free = true
							print("[打蛋器] 修正了动画queue_free的时间点为:", vortex_duration)
			
			# 如果找到了方法轨道，添加prepare_for_deletion调用
			if method_track_index >= 0:
				# 在queue_free之前添加prepare_for_deletion的调用
				var prepare_time = vortex_duration - 0.1 # 比queue_free早一点
				
				# 创建方法调用
				var prepare_call = {
					"args": [],
					"method": &"prepare_for_deletion"
				}
				
				# 添加到动画
				if not found_queue_free:
					# 如果没有找到queue_free，那么可能需要再创建一个
					var queue_free_call = {
						"args": [],
						"method": &"queue_free"
					}
					anim.track_insert_key(method_track_index, vortex_duration, queue_free_call)
					print("[打蛋器] 添加了queue_free调用在时间点:", vortex_duration)
				
				# 添加prepare_for_deletion调用
				anim.track_insert_key(method_track_index, prepare_time, prepare_call)
				print("[打蛋器] 添加了prepare_for_deletion调用在时间点:", prepare_time)
	
	$DurationTimer.one_shot = true
	
	$VortexTimer.wait_time = 1.0 / damage_tick
	$VortexTimer.one_shot = false
	
	# 播放动画
	$AnimationPlayer.play("vortex")
	
	# 发射到目标位置
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_position, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): 
		# 到达目标位置时激活
		is_active = true
		is_flying = false
		
		# 确保持续时间正确设置
		print("[打蛋器] 当前参数 - 半径:", vortex_radius, "拉力:", pull_force, "持续时间:", vortex_duration)
		
		# 启动伤害计时器
		$VortexTimer.start()
		
		# 处理长持续时间
		if is_long_duration:
			# 启动自定义删除计时器
			var delete_timer = get_node_or_null("DeleteTimer")
			if delete_timer:
				print("[打蛋器] 启动长持续时间计时器:", vortex_duration, "秒")
				delete_timer.start()
		else:
			# 普通持续时间使用DurationTimer
			$DurationTimer.wait_time = vortex_duration
			print("[打蛋器] 启动标准计时器:", $DurationTimer.wait_time, "秒")
			$DurationTimer.start()
		
		# 启用碰撞检测
		$CollisionShape2D.disabled = false
		
		# 触发重绘以显示范围
		queue_redraw()
		
		# 初始查找敌人
		find_enemies_by_group()
	)

# 每帧更新函数，用于实时应用吸引力
func _physics_process(delta):
	# 只有在激活状态且不在飞行阶段才应用吸引力
	if is_active and not is_flying:
		# 对范围内的敌人应用吸引力
		apply_pull_to_enemies(delta)

# 对范围内所有敌人应用吸引力
func apply_pull_to_enemies(delta):
	for enemy in enemies_in_area:
		if is_instance_valid(enemy):
			apply_pull_to_enemy(enemy, delta)

# 对单个敌人应用吸引力
func apply_pull_to_enemy(enemy, delta):
	if not is_instance_valid(enemy):
		return
	
	# 计算方向和距离
	var dir_to_center = global_position - enemy.global_position
	var distance = dir_to_center.length()
	
	# 随距离减弱的吸引力 - 基础数值不变，直接使用传入的pull_force
	var strength = pull_force * (1.0 - min(distance / vortex_radius, 0.9))
	var pull_direction = dir_to_center.normalized()
	
	# 尝试应用吸引力
	if enemy.has_method("external_velocity"):
		# 如果敌人有专门的外部速度方法
		enemy.external_velocity(pull_direction * strength)
	else:
		# 直接修改速度或位置 - 删除额外乘数30，直接使用strength
		if enemy.get("velocity") != null:
			enemy.velocity += pull_direction * strength * delta
		
		# 轻微直接移动敌人位置 - 调整比例便于观察效果
		enemy.global_position += pull_direction * strength * delta * 0.1

# 通过组查找所有敌人
func find_enemies_by_group():
	# 只检查是否在飞行阶段
	# 删除is_active检查，确保能持续找到敌人
	if is_flying:
		return
		
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	var enemies_found = 0
	
	for enemy in all_enemies:
		if is_instance_valid(enemy) and is_enemy(enemy):
			# 计算到敌人的距离
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= vortex_radius: # 范围与可视化圆圈一样大
				if not enemies_in_area.has(enemy):
					enemies_in_area.append(enemy)
					apply_damage_to_enemy(enemy, damage) # 使用配置的伤害值
					enemies_found += 1
	
	# 如果找到了新敌人，打印一下，便于调试
	if enemies_found > 0:
		print("[打蛋器] 发现", enemies_found, "个新敌人")

# 当敌人进入范围
func _on_body_entered(body):
	# 删除is_active检查，只要不是飞行阶段就继续处理碰撞
	if is_flying:
		return
		
	if is_enemy(body) and not enemies_in_area.has(body):
		enemies_in_area.append(body)
		apply_damage_to_enemy(body, damage) # 使用配置的伤害值
		print("[打蛋器] 有敌人进入范围，应用伤害")

# 当敌人离开范围
func _on_body_exited(body):
	if enemies_in_area.has(body):
		enemies_in_area.erase(body)

# 定时器回调 - 定期伤害敌人
func _on_vortex_timer_timeout():
	# 放宽条件，只要不是飞行阶段就继续造成伤害
	# 删除is_active检查，因为DurationTimer可能会将其设置为false
	if is_flying:
		return
		
	# 打印调试信息，便于跟踪计时器是否正常触发
	print("[打蛋器] 伤害计时器触发，当前敌人数:", enemies_in_area.size())
		
	# 更新敌人列表
	find_enemies_by_group()
	
	# 对所有敌人造成伤害
	damage_all_enemies()

# 对所有敌人造成伤害
func damage_all_enemies():
	# 放宽条件，只要不是飞行阶段就继续造成伤害
	# 删除is_active检查，因为DurationTimer可能会将其设置为false
	if is_flying:
		return
		
	var valid_enemies = 0
	for i in range(enemies_in_area.size() - 1, -1, -1):
		var enemy = enemies_in_area[i]
		
		if not is_instance_valid(enemy):
			# 移除无效敌人
			enemies_in_area.remove_at(i)
			continue
			
		# 直接造成伤害，使用配置的伤害值
		if apply_damage_to_enemy(enemy, damage): # 使用传入的damage值
			valid_enemies += 1
	
	if valid_enemies > 0:
		print("[打蛋器] 对", valid_enemies, "个敌人造成伤害，伤害值:", damage)

# 绘制可视化
func _draw():
	# 只要不在飞行阶段就绘制范围
	# 删除is_active检查，确保一直能看到范围
	if not is_flying:
		draw_circle(Vector2.ZERO, vortex_radius, Color(0.5, 0.3, 0, 0.2))
		draw_arc(Vector2.ZERO, vortex_radius, 0, 2 * PI, 32, Color(1, 0.5, 0, 0.5), 2)

# 手动对敌人应用伤害
func apply_damage_to_enemy(enemy, amount):
	# 只检查敌人是否有效和是否在飞行阶段
	# 删除is_active检查，确保在整个持续时间内都能造成伤害
	if is_flying or not is_instance_valid(enemy):
		return false
		
	var damage_dealt = false
	
	# 尝试不同的伤害方法
	if enemy.has_method("_on_hurt_box_hurt"):
		# 直接调用伤害方法
		var direction = (enemy.global_position - global_position).normalized()
		enemy._on_hurt_box_hurt(amount, direction, 1.0)
		damage_dealt = true
	elif enemy.has_method("take_damage"):
		enemy.take_damage(amount)
		damage_dealt = true
	elif enemy.has_method("hurt"):
		enemy.hurt(amount)
		damage_dealt = true
	elif enemy.has_method("damage"):
		enemy.damage(amount)
		damage_dealt = true
	elif enemy.has_method("handle_hurt"):
		# 尝试直接调用handle_hurt
		var direction = (enemy.global_position - global_position).normalized()
		enemy.handle_hurt(amount, direction, 1.0)
		damage_dealt = true
	elif enemy.get("hp") != null:
		# 直接修改hp
		enemy.hp -= amount
		damage_dealt = true
	
	if damage_dealt:
		debug_damage_count += 1
		emit_signal("hit_enemy", enemy, amount)
		
	return damage_dealt

# 判断是否为敌人
func is_enemy(body):
	# 检查对象是否属于enemy组
	if body.is_in_group("enemy"):
		return true
	
	# 检查节点名称是否包含enemy
	if "enemy" in body.name.to_lower():
		return true
	
	# 检查节点路径是否包含enemy目录
	if "enemy" in body.get_path().to_lower():
		return true
	
	# 其他潜在的敌人判断逻辑
	# 例如：检查是否有特定的敌人方法
	if body.has_method("handle_hurt") or body.has_method("_on_hurt_box_hurt"):
		return true
	
	return false

# 清理函数 - 当打蛋器被移除时
func _exit_tree():
	# 确保所有计时器都已停止
	if $VortexTimer and $VortexTimer.is_inside_tree():
		$VortexTimer.stop()
	
	if $DurationTimer and $DurationTimer.is_inside_tree():
		$DurationTimer.stop()
	
	# 清空引用，帮助垃圾回收
	enemies_in_area.clear()

# 这个函数将在效果结束时被调用，执行最终清理并销毁对象
func prepare_for_deletion():
	print("[打蛋器] 准备删除，执行最终清理，持续时间:", vortex_duration, "秒")
	
	# 停止所有计时器
	if $VortexTimer and $VortexTimer.is_inside_tree():
		$VortexTimer.stop()
	
	if $DurationTimer and $DurationTimer.is_inside_tree():
		$DurationTimer.stop()
	
	# 停止长持续时间计时器
	var delete_timer = get_node_or_null("DeleteTimer")
	if delete_timer and delete_timer.is_inside_tree():
		delete_timer.stop()
	
	# 禁用碰撞
	$CollisionShape2D.disabled = true
	
	# 将自身标记为非活动
	is_active = false
	is_flying = true
	
	# 清空敌人列表
	enemies_in_area.clear()
	
	# 停止任何正在播放的动画
	if $AnimationPlayer and $AnimationPlayer.is_inside_tree():
		$AnimationPlayer.stop()
	
	# 创建一个淡出效果
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(func():
		# 直接调用queue_free确保对象被销毁
		queue_free()
	)

# 处理DurationTimer超时 - 打蛋器持续时间结束
func _on_duration_timer_timeout():
	print("[打蛋器] 持续时间计时器结束，但保持效果直到动画结束")
	
	# 确保这里不会错误地将is_active设置为false
	# 直接明确设置为true，防止其他地方可能错误修改了它
	is_active = true
	
	# 确保伤害计时器仍在运行
	if not $VortexTimer.is_stopped():
		print("[打蛋器] 伤害计时器正在运行")
	else:
		print("[打蛋器] 重新启动伤害计时器")
		$VortexTimer.start()
		
	# 确保碰撞检测正常工作
	$CollisionShape2D.disabled = false
	
	# 如果是长持续时间，我们等待DeleteTimer结束
	var delete_timer = get_node_or_null("DeleteTimer")
	if delete_timer and delete_timer.time_left > 0:
		print("[打蛋器] 长持续时间模式，还剩:", delete_timer.time_left, "秒")

# 获取随机方向
func get_player_direction():
	# 使用当前时间作为随机种子，确保每次都不同
	seed(Time.get_ticks_msec())
	
	# 生成一个随机角度(0-360度)
	var random_angle = randf_range(0, 2 * PI)
	
	# 添加一点混沌效果 - 使用时间和等级添加一些变化
	var chaos_factor = sin(Time.get_ticks_msec() * 0.001 + level * 0.5) * 0.2
	random_angle += chaos_factor
	
	# 将角度转换为方向向量
	direction = Vector2(cos(random_angle), sin(random_angle))
	
	print("[打蛋器] 生成随机方向:", direction, "角度:", rad_to_deg(random_angle), "度")
	
	return direction
