extends TextureRect
class_name CutsceneRect

## Used internally. Do not use externally.
## Async.
static func item_smooth_param_vec2(item : CanvasItem, param : String, vec2 : Vector2, speed : float):
    var start_vec2 : Vector2 = item.material.get_shader_parameter(param)
    
    await Engine.get_main_loop().process_frame
    if !is_instance_valid(item):
        return
    
    var time_passed = 0.0
    while time_passed < 1.0:
        var delta = Engine.get_main_loop().current_scene.get_process_delta_time()
        time_passed = clamp(time_passed + delta * speed, 0.0, 1.0)
        if CutsceneInstance.should_skip_anims(): time_passed = 1.0
        
        var real_vec2 = start_vec2.lerp(vec2, smoothstep(0.0, 1.0, time_passed))
        item.material.set_shader_parameter(param, real_vec2)
        
        await Engine.get_main_loop().process_frame
        if !is_instance_valid(item):
            return

# Used internally.
var is_bg : bool = false

## Set the position for the given image.
## [br]
## Positions are based on the height of the cutscene screen, with 1.0 representing
## the distance from the center of the screen to the top or bottom.
## [br]
## So, a position of Vector2(1.0, 0.0) is only about half way towards the right side
## of a 16:9 screen.
## [br]
## Applies instantly.
func set_new_position(pos : Vector2):
    material.set_shader_parameter("position", pos)

## Set the position for the given image smoothly. See `image_set_position` for more information.
## [br]
## Async.
func smooth_position(pos : Vector2, speed : float = 0.0):
    await CutsceneRect.item_smooth_param_vec2(self, "position", pos, speed if speed > 0.0 else (CutsceneInstance.bg_move_speed if is_bg else CutsceneInstance.tachie_move_speed))

## Set the scale for the given image.
## [br]
## Applies instantly.
func set_new_scale(new_scale : Vector2):
    material.set_shader_parameter("scale", new_scale)

## Set the scale for the given image smoothly.
## [br]
## Async.
func smooth_scale(new_scale : Vector2, speed : float = 0.0):
    await CutsceneRect.item_smooth_param_vec2(self, "scale", new_scale, speed if speed > 0.0 else (CutsceneInstance.bg_move_speed if is_bg else CutsceneInstance.tachie_move_speed))

## Set the texture for the given image.
## [br]
## Applies instantly.
func set_new_texture(tex : Texture2D):
    texture = tex

## Used internally. Do not use externally.
## Async.
static func item_transition(item : CanvasItem, property : String, start, end, speed):
    item.set_indexed(property, start)
    
    await Engine.get_main_loop().process_frame
    if !is_instance_valid(item):
        return
    
    var time_passed = 0.0
    while time_passed < 1.0:
        var delta = Engine.get_main_loop().current_scene.get_process_delta_time()
        time_passed = clamp(time_passed + delta * speed, 0.0, 1.0)
        if CutsceneInstance.should_skip_anims(): time_passed = 1.0
        
        item.set_indexed(property, smoothstep(start, end, time_passed))
        
        await Engine.get_main_loop().process_frame
        if !is_instance_valid(item):
            return

## Used internally. Do not use externally.
## Async.
static func item_hide(item : CanvasItem, speed : float):
    await CutsceneRect.item_transition(item, "modulate:a", 1.0, 0.0, speed)

## Used internally. Do not use externally.
## Async.
static func item_show(item : CanvasItem, speed : float):
    await CutsceneRect.item_transition(item, "modulate:a", 0.0, 1.0, speed)

## Hide the given image, playing a fade-out animation.
## [br]
## Async.
func fade_hide(speed : float = 0.0):
    speed = speed if speed > 0.0 else (CutsceneInstance.bg_fade_speed if is_bg else CutsceneInstance.tachie_fade_speed)
    await CutsceneRect.item_transition(self, "modulate:a", 1.0, 0.0, speed)

## Show the given image, playing a fade-in animation.
## [br]
## Async.
func fade_show(speed : float = 0.0):
    speed = speed if speed > 0.0 else (CutsceneInstance.bg_fade_speed if is_bg else CutsceneInstance.tachie_fade_speed)
    await CutsceneRect.item_transition(self, "modulate:a", 0.0, 1.0, speed)
    print("done fading item")

# -- internals --

func _process(delta : float):
    material.set_shader_parameter("screen_size", get_parent().dummy_control.size)

func _init():
    expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    
    stretch_mode = STRETCH_KEEP_ASPECT_CENTERED
    anchor_right = 1
    anchor_bottom = 1
    offset_right = 0
    offset_bottom = 0
    
    material = preload("../shader/CutsceneImageMat.tres").duplicate()
    
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
