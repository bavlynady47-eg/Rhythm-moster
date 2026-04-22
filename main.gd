extends Node2D

# --- STYLE & VISUAL SETTINGS ---
var lane_colors = [Color.MEDIUM_PURPLE, Color.CYAN, Color.SPRING_GREEN, Color.HOT_PINK]
var flash_opacity = [0.0, 0.0, 0.0, 0.0]
var last_judgement = ""
var judgement_color = Color.WHITE
var judgement_scale = 1.0 # For the "pop" effect

# --- LEVEL DATA ---
var notes = [
	[2, 4, 7, 9, 12, 14, 16, 18, 22, 24, 28, 30, 34, 38, 42],      
	[3, 5, 8, 10, 12, 14, 16, 18, 23, 25, 29, 31, 35, 39, 43],     
	[2.5, 4.5, 7.5, 9.5, 13, 15, 17, 19, 24, 26, 30, 32, 36, 40, 44], 
	[3.5, 5.5, 8.5, 10.5, 13, 15, 17, 19, 25, 27, 31, 33, 37, 41, 45] 
]

var score := 0
var combo := 0
var max_combo := 0
var game_over := false

func _process(delta: float) -> void:
	queue_redraw()
	
	if game_over:
		return 

	# 1. ANIMATION: Shrink judgement text over time
	judgement_scale = lerp(judgement_scale, 1.0, 0.1)

	# 2. ANIMATION: Fade lane highlights
	for i in 4:
		flash_opacity[i] = lerp(flash_opacity[i], 0.0, 0.1)

	var current_time = $conductor.get_playback_position() * 120 / 60
	
	# WIN CONDITION
	if notes[0].is_empty() and notes[1].is_empty() and notes[2].is_empty() and notes[3].is_empty():
		if current_time > 48: 
			game_over = true

	# MISS LOGIC
	for i in 4:
		var lane = notes[i]
		if not lane.is_empty():
			if lane[0] < current_time - 0.5:
				lane.pop_front()
				combo = 0
				last_judgement = "MISS"
				judgement_color = Color.DARK_GRAY
				judgement_scale = 1.2

func _draw() -> void:
	var ui_font = ThemeDB.fallback_font
	var current_beat = $conductor.get_playback_position() * 120 / 60
	
	if game_over:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.9))
		draw_string(ui_font, Vector2(640, 250), "STAGE CLEAR!", HORIZONTAL_ALIGNMENT_CENTER, -1, 80, Color.GOLD)
		draw_string(ui_font, Vector2(640, 350), "SCORE: " + str(score), HORIZONTAL_ALIGNMENT_CENTER, -1, 40)
		draw_string(ui_font, Vector2(640, 420), "MAX COMBO: " + str(max_combo), HORIZONTAL_ALIGNMENT_CENTER, -1, 30, Color.CYAN)
		draw_string(ui_font, Vector2(640, 600), "Press [R] to Restart", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.WHITE)
		return

	# --- BACKGROUND PULSE ---
	# Changes brightness based on the beat
	var pulse = (sin(current_beat * PI) + 1.0) * 0.02
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.01 + pulse, 0.01, 0.05 + pulse)) 
	
	# --- DRAW LANES ---
	for i in 4:
		var x_pos = 100 * i + 200
		draw_rect(Rect2(x_pos, 0, 100, 720), Color(1, 1, 1, 0.02))
		if flash_opacity[i] > 0.01:
			var flash_col = lane_colors[i]
			flash_col.a = flash_opacity[i] * 0.3
			draw_rect(Rect2(x_pos, 0, 100, 620), flash_col)

	# Judgement Line
	draw_line(Vector2(200, 620), Vector2(600, 620), Color.WHITE, 3)

	# Falling notes with a "Glow" line
	for i in 4:
		for note in notes[i]:
			var y = 620 + 150 * (current_beat - note) 
			if y > -50 and y < 750:
				var start = Vector2(100 * i + 210, y)
				var end = Vector2(100 * (i + 1) + 190, y)
				# Draw the glow
				draw_line(start, end, lane_colors[i], 12)
				# Draw the core
				draw_line(start, end, Color.WHITE, 2)

	# --- UI WITH POP ANIMATION ---
	draw_string(ui_font, Vector2(650, 100), "SCORE: " + str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 40)
	draw_string(ui_font, Vector2(650, 160), "COMBO: " + str(combo), HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	
	if last_judgement != "":
		var font_size = 60 * judgement_scale
		draw_string(ui_font, Vector2(400, 350), last_judgement, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, judgement_color)

func _unhandled_key_input(event: InputEvent) -> void:
	if game_over and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
		
	if not game_over:
		if event.is_action_pressed("1"): _handle_lane_press(0)
		elif event.is_action_pressed("2"): _handle_lane_press(1)
		elif event.is_action_pressed("3"): _handle_lane_press(2)
		elif event.is_action_pressed("4"): _handle_lane_press(3)

func _handle_lane_press(lane: int) -> void:
	var lane_notes = notes[lane]
	if lane_notes.is_empty(): return
	
	var note = lane_notes[0]
	var current_beat = $conductor.get_playback_position() * 120 / 60
	var diff = abs(current_beat - note)
	
	if diff < 0.5:
		flash_opacity[lane] = 1.0
		judgement_scale = 1.5 # Trigger the text pop
		lane_notes.pop_front()
		
		if diff < 0.15:
			last_judgement = "PERFECT!"
			judgement_color = Color.GOLD
			score += 100
			combo += 1
		else:
			last_judgement = "GREAT"
			judgement_color = Color.CYAN
			score += 50
			combo += 1
		
		if combo > max_combo:
			max_combo = combo
