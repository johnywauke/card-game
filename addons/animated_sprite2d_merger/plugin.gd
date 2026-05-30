@tool
extends EditorPlugin

const PLUGIN_MENU_ITEM = "Merge Selected AnimatedSprite2D Nodes"

func _enter_tree():
	add_tool_menu_item(PLUGIN_MENU_ITEM, _on_merge_selected_animated_sprites)

func _exit_tree():
	remove_tool_menu_item(PLUGIN_MENU_ITEM)

	
func _on_merge_selected_animated_sprites():
	var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
	var animated_sprites = []

	# Filter only AnimatedSprite2D nodes
	for node in selected_nodes:
		if node is AnimatedSprite2D:
			animated_sprites.append(node)

	if animated_sprites.size() < 2:
		show_error_msg("Please select at least 2 AnimatedSprite2D nodes to merge.")
		return

	# Create merger and perform merge
	var merger = AnimatedSprite2DMerger.new()
	merger.merge_sprites(animated_sprites)

func show_error_msg(message: String):
	print_rich("[color=red][b]"+ message +"[/b][/color]")

class AnimatedSprite2DMerger:

	func merge_sprites(sprites: Array):
		if sprites.is_empty():
			return

		print("[AnimatedSprite2D Merger] Starting merge process...")

		# Create the merged SpriteFrames by combining existing ones
		var merged_sprite_frames = create_merged_sprite_frames(sprites)
		if not merged_sprite_frames:
			show_error_msg("Failed to create merged SpriteFrames.")
			return

		# Create the merged AnimatedSprite2D
		var merged_sprite = create_merged_sprite(merged_sprite_frames, sprites[0])

		# Add to scene
		var scene_root = EditorInterface.get_edited_scene_root()
		if scene_root:
			scene_root.add_child(merged_sprite)
			merged_sprite.owner = scene_root
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(merged_sprite)
			print("[AnimatedSprite2D Merger] Successfully created merged sprite: ", merged_sprite.name)
		else:
			show_error_msg("No scene root found. Please open a scene first.")

	func create_merged_sprite_frames(sprites: Array) -> SpriteFrames:
		var merged_frames = SpriteFrames.new()
		var animation_count = 0
		var total_frames = 0

		for sprite in sprites:
			if not sprite.sprite_frames:
				print("[AnimatedSprite2D Merger] Skipping sprite '%s' - no SpriteFrames" % sprite.name)
				continue

			var sprite_name = sprite.name
			var sprite_frames = sprite.sprite_frames
			var anim_names = sprite_frames.get_animation_names()

			for anim_name in anim_names:
				if anim_name == "default" and anim_names.size() > 1:
					# Skip empty default animations when there are other animations
					if sprite_frames.get_frame_count(anim_name) == 0:
						continue

				var frame_count = sprite_frames.get_frame_count(anim_name)
				if frame_count == 0:
					print("[AnimatedSprite2D Merger] Skipping empty animation '%s' from sprite '%s'" % [anim_name, sprite_name])
					continue

				# Create unique animation name
				var merged_anim_name = anim_name
				var original_name = merged_anim_name
				var counter = 2

				# Handle duplicate animation names
				while merged_frames.has_animation(merged_anim_name):
					merged_anim_name = str(counter).pad_zeros(3) + "_" + original_name
					counter += 1

				# Add the animation to merged frames
				merged_frames.add_animation(merged_anim_name)

				# Copy animation properties
				merged_frames.set_animation_speed(merged_anim_name, sprite_frames.get_animation_speed(anim_name))
				merged_frames.set_animation_loop(merged_anim_name, sprite_frames.get_animation_loop(anim_name))

				# Copy all frames with their durations (keeping original atlas textures)
				for frame_idx in range(frame_count):
					var frame_texture = sprite_frames.get_frame_texture(anim_name, frame_idx)
					var frame_duration = sprite_frames.get_frame_duration(anim_name, frame_idx)

					if frame_texture:
						merged_frames.add_frame(merged_anim_name, frame_texture, frame_duration)
						total_frames += 1

				animation_count += 1
				print("[AnimatedSprite2D Merger] Added animation '%s' with %d frames" % [merged_anim_name, frame_count])

		print("[AnimatedSprite2D Merger] Merged %d animations with %d total frames" % [animation_count, total_frames])

		# Remove default animation if it's empty and we have other animations
		if merged_frames.has_animation("default") and merged_frames.get_animation_names().size() > 1:
			if merged_frames.get_frame_count("default") == 0:
				merged_frames.remove_animation("default")
				print("[AnimatedSprite2D Merger] Removed empty default animation")

		return merged_frames

	func create_merged_sprite(sprite_frames: SpriteFrames, reference_sprite: AnimatedSprite2D) -> AnimatedSprite2D:
		var merged_sprite = AnimatedSprite2D.new()
		merged_sprite.name = "MergedAnimatedSprite2D"

		# Copy transform and visual properties from reference sprite
		merged_sprite.transform = reference_sprite.transform
		merged_sprite.modulate = reference_sprite.modulate
		merged_sprite.self_modulate = reference_sprite.self_modulate
		merged_sprite.show_behind_parent = reference_sprite.show_behind_parent
		merged_sprite.top_level = reference_sprite.top_level
		merged_sprite.clip_children = reference_sprite.clip_children
		merged_sprite.texture_filter = reference_sprite.texture_filter
		merged_sprite.texture_repeat = reference_sprite.texture_repeat

		# Copy animation properties
		merged_sprite.autoplay = reference_sprite.autoplay
		merged_sprite.frame_progress = reference_sprite.frame_progress
		merged_sprite.speed_scale = reference_sprite.speed_scale

		# Set the merged SpriteFrames
		merged_sprite.sprite_frames = sprite_frames

		# Set first animation as current if available
		var anim_names = sprite_frames.get_animation_names()
		if not anim_names.is_empty():
			merged_sprite.animation = anim_names[0]

			# If reference sprite had a valid animation, try to find a similar one
			if reference_sprite.sprite_frames and reference_sprite.sprite_frames.has_animation(reference_sprite.animation):
				var ref_anim = reference_sprite.animation
				# Look for animation that starts with original animation
				for anim_name in anim_names:
					if str(anim_name) == ref_anim:
						merged_sprite.animation = anim_name
						break

		print("[AnimatedSprite2D Merger] Created merged sprite with %d animations" % anim_names.size())
		return merged_sprite

	func show_error_msg(message: String):
		print_rich("[color=red][b]"+ message +"[/b][/color]")