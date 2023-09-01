extends CanvasLayer
class_name CutsceneInstance

# Custom input actions you can add:
# "cutscene_advance" - to advance text. pressing down on this also causes currently-running animations to be skipped.
#   common: m1, down arrow
# "cutscene_instant_text" - to make text instantly appear, but not advance. also doesn't skip animations.
#   common: on controllers, the "cancel" button. not needed if that button is bound to "ui_cancel".
# "cutscene_skip" - hold to skip animations, including the text type-in effect.
#   common: ctrl. PLEASE DO NOT PUT THIS ON ALT. PUTTING IT ON ALT MAKES IT HARD TO ALT TAB.

# Rate at which new characters are added to the textbox per second.
const typein_speed = 90.0
# Number of textboxes to skip per second when skipping.
# Note: skipping is slowed down by one frame per other animation (tachie/background transitions etc).
const skip_rate = 20.0
# Speed at which tachie (standing sprites) fade in. Higher values make them take less time. Reciprocal of seconds.
const tachie_fade_speed = 3.0
# Speed at which backgrounds fade in.
const bg_fade_speed = 1.5
# Speed at which the textbox fades in.
const textbox_fade_speed = 4.0
# Speed at which images move when smoothly moved. Reciprocal of seconds.
const tachie_move_speed = 4.0
# Speed at which images move when smoothly moved. Reciprocal of seconds.
const bg_move_speed = 0.5

# Emitted when the cutscene is ready to continue. You usually don't need to touch this directly.
signal cutscene_continue

## Emitted when the cutscene is finished.
signal cutscene_finished

## Used to translate global world positions into the adjustment fractions used for positioning tachie and textboxes.
static func globalpos_to_screen_fraction(vec : Vector2):
    var viewport : SubViewport = Engine.get_main_loop().get_root()
    var size =  viewport.get_visible_rect().size
    var xform = viewport.canvas_transform
    var local_vec = xform * (vec)
    var fraction_vec = (local_vec - size/2.0)/size.y*2.0
    return fraction_vec

## Call to check whether any cutscenes are currently running.
## [br]
## For example, you can use this function to ignore input or pause the game when cutscenes are running.
static func cutscene_is_running():
    return Engine.get_main_loop().get_nodes_in_group("CutsceneInstance").size() > 0

## Sets the textbox and makes the cutscene instance start to type in the new text and wait for input.
## [br]
## Async. Example: `await my_cutscene_instance.set_text("Hello!!!")`
func set_text(text : String):
    var label = current_textbox.get_node("Label")
    
    label.bbcode_enabled = true
    label.text = text
    
    if current_textbox == chat_textbox:
        label.offset_left = _chat_textbox_alignment
        chat_portrait.visible = false
        
        var size = _estimate_good_chat_size()
        
        if chat_portrait.texture:
            chat_portrait.visible = true
            label.offset_left += chat_portrait.size.x + 16
            size.x += chat_portrait.size.x + 16
            size.y = max(size.y, chat_portrait.size.y)
            fix_chatbox_size(size)
        else:
            fix_chatbox_size(size)
    
    current_textbox.visible = true
    if current_textbox.modulate.a < 1.0:
        textbox_show()
    
    _visible_characters = 0.0
    if CutsceneInstance.should_skip_anims() or CutsceneInstance.should_use_instant_text():
        _visible_characters = -1
    label.visible_characters = int(_visible_characters)
    
    await cutscene_continue

## Clears the textbox.
func clear_text():
    var label = current_textbox.get_node("Label")
    current_textbox.visible = true
    label.bbcode_enabled = true
    label.text = ""
    label.visible_characters = -1

var images : Dictionary = {}

## Adds a tachie (standing sprite) to the scene, returning a CutsceneRect.
func add_tachie(new_texture : Texture2D) -> CutsceneRect:
    var rect = CutsceneRect.new()
    rect.texture = new_texture
    add_child(rect)
    rect.material.set_shader_parameter("screen_size", dummy_control.size)
    
    images[rect] = null
    return rect

## Adds a background to the scene, returning a CutsceneRect.
func add_background(texture : Texture2D) -> CutsceneRect:
    var rect = add_tachie(texture)
    rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    rect.material.set_shader_parameter("is_background", true)
    RenderingServer.canvas_item_set_z_index(rect.get_canvas_item(), -1)
    return rect

## Hide the current text box, playing a fade-out animation.
## [br]
## Async.
func textbox_hide():
    await CutsceneRect.item_hide(current_textbox, textbox_fade_speed)
    chat_portrait.texture = null
    adv_portrait.texture = null

## Show the current text box, playing a fade-in animation.
## [br]
## Async.
func textbox_show():
    await CutsceneRect.item_show(current_textbox, textbox_fade_speed)

## Switches to the ADV-style textbox.
## [br]
## Applies instantly.
func textbox_set_adv():
    current_textbox = adv_textbox
    adv_textbox.show()
    chat_textbox.hide()
    chat_portrait.texture = null
    adv_portrait.texture = null

# used internally.
func _estimate_good_chat_size():
    var ideal_ar = 2
    
    var label : RichTextLabel = (chat_textbox.get_node("Label") as RichTextLabel)
    
    var old_autowrap = label.autowrap_mode
    var old_fit_content = label.fit_content
    
    var old_offset_top = label.offset_top
    var old_offset_left = label.offset_left
    var old_offset_right = label.offset_right
    var old_offset_bottom = label.offset_bottom
    
    label.visible_characters = -1
    label.autowrap_mode = TextServer.AUTOWRAP_OFF
    label.fit_content = true
    label.size.x = 0
    label.size.y = 0
    
    var size = label.size
    
    if size.x / size.y > ideal_ar:
        var square_sidelen = sqrt(size.x * size.y)
        label.autowrap_mode = old_autowrap
        label.size.x = square_sidelen*2.0
        label.size.y = 0
        label.propagate_notification(RichTextLabel.NOTIFICATION_VISIBILITY_CHANGED)
        if label.get_line_count() > 1:
            var good_y = label.size.y
            while label.size.y == good_y and label.size.x > 0:
                label.size.x -= 5
                label.propagate_notification(RichTextLabel.NOTIFICATION_VISIBILITY_CHANGED)
            label.size.x += 5
            label.propagate_notification(RichTextLabel.NOTIFICATION_VISIBILITY_CHANGED)
            label.size.y = good_y
        size = label.size
    
    label.fit_content = old_fit_content
    label.autowrap_mode = old_autowrap
    
    label.offset_top = old_offset_top
    label.offset_left = old_offset_left
    label.offset_right = old_offset_right
    label.offset_bottom = old_offset_bottom
    
    size.x += 1 # just to help make 100% sure it doesn't clip or wrap unnecessarily
    
    return size

var chat_pos : Vector2 = Vector2()
var chat_orientation : String = "upleft"

## If in chat-bubble mode, set the face of the next textboxes. Pass `null` to clear it.
## [br]
## Applies instantly.
func chat_set_face(face : Texture2D, flipped : bool = false):
    chat_portrait.texture = face
    if flipped:
        chat_portrait.material.set_shader_parameter("scale", Vector2(-1.0, 1.0))
    else:
        chat_portrait.material.set_shader_parameter("scale", Vector2(1.0, 1.0))

## If in ADV mode, set the face of the next textboxes. Pass `null` to clear it.
## [br]
## Applies instantly.
func adv_set_face(face : Texture2D, flipped : bool = false):
    adv_portrait.texture = face
    if flipped:
        adv_portrait.material.set_shader_parameter("scale", Vector2(-1.0, 1.0))
    else:
        adv_portrait.material.set_shader_parameter("scale", Vector2(1.0, 1.0))

## Switches to the chat-bubble-style textbox.
## [br]
## Applies instantly.
func textbox_set_chat(pos : Vector2, orientation : String = "upleft"):
    current_textbox = chat_textbox
    chat_textbox.show()
    adv_textbox.hide()
    
    chat_pos = pos
    chat_orientation = orientation
    chat_portrait.texture = null
    adv_portrait.texture = null

## Sets the speaker name. To empty, set to an empty string: `""`
## [br]
## Applies instantly. However, the nametag is only visible when text is drawn.
func set_nametag(tag : String):
    adv_textbox.get_node("Nametag").text = tag
    chat_textbox.get_node("Nametag").text = tag

## Used internally.
## [br]
## However, if the automatic chatbox size for a given message is too small, you can use this function to override it.
func fix_chatbox_size(size : Vector2):
    var label : RichTextLabel = chat_textbox.get_node("Label")
    var outer_margin_x = label.offset_left - label.offset_right
    var outer_margin_y = label.offset_top - label.offset_bottom
    
    if chat_portrait.texture:
        outer_margin_x -= chat_portrait.size.x
    
    size += Vector2(outer_margin_x, outer_margin_y)
    
    var center = dummy_control.size/2
    var new_offset = -size/2
    
    if chat_orientation == "upleft":
        chat_textbox.material.set_shader_parameter("scale", Vector2(1.0, 1.0))
        new_offset = Vector2(0, 0)
    elif chat_orientation == "upright":
        chat_textbox.material.set_shader_parameter("scale", Vector2(-1.0, 1.0))
        new_offset = Vector2(-size.x, 0)
    elif chat_orientation == "downleft":
        chat_textbox.material.set_shader_parameter("scale", Vector2(1.0, -1.0))
        new_offset = Vector2(0, -size.y)
    elif chat_orientation == "downright":
        chat_textbox.material.set_shader_parameter("scale", Vector2(-1.0, -1.0))
        new_offset = -size
    
    var new_pos = center + new_offset + chat_pos*0.5*dummy_control.size.y
    
    chat_textbox.position = new_pos
    chat_textbox.size = size
    
    chat_textbox.material.set_shader_parameter("screen_size", size)

## Destroy an image, removing it from the scene and freeing its memory.
## [br]
## The underlying texture will continue to exist until you stop using it (write `null` to whatever variable contains it). If you don't have the texture in a variable anywhere, then it will be freed immediately.
func image_destroy(rect : CutsceneRect):
    if rect in images:
        var _unused = images.erase(rect)
    if rect.get_parent():
        rect.get_parent().remove_child(rect)
    if is_instance_valid(rect):
        rect.queue_free()

class MultiAsyncAwaiter extends RefCounted:
    signal all_finished
    var count : int = 0
    func connectify(callable : Callable):
        count += 1
        await callable.call()
        count -= 1
        if count == 0:
            all_finished.emit()

## Call at the end of the cutscene to ensure proper cleanup.
func finish():
    var funcs_to_wait = []
    
    var waiter : MultiAsyncAwaiter = MultiAsyncAwaiter.new()
    for image in images:
        if image.modulate.a > 0.0 and is_instance_valid(image):
            waiter.connectify(image.fade_hide)
    waiter.connectify(textbox_hide)
    
    await waiter.all_finished
    
    images = {}
    
    queue_free()
    cutscene_finished.emit()

# _____________________________________________
# |                                           |
# |   MiniMirage internals. Here be dragons.  |
# |                                           |
# _____________________________________________

var adv_textbox : Control = null
var chat_textbox : NinePatchRect = null
var current_textbox : Control = null
var chat_portrait : TextureRect = null
var adv_portrait : TextureRect = null
var _chat_textbox_alignment : float = 0.0

var dummy_control : Control = null

func _ready():
    dummy_control = Control.new()
    add_child(dummy_control)
    dummy_control.anchor_right = 1
    dummy_control.anchor_bottom = 1
    dummy_control.offset_right = 0
    dummy_control.offset_bottom = 0
    
    add_to_group("CutsceneInstance")
    
    adv_textbox = preload("Textbox.tscn").instantiate()
    chat_textbox = preload("ChatTextbox.tscn").instantiate()
    add_child(adv_textbox)
    add_child(chat_textbox)
    
    adv_textbox.modulate.a = 0.0
    chat_textbox.modulate.a = 0.0
    _chat_textbox_alignment = chat_textbox.get_node("Label").offset_left
    chat_portrait = chat_textbox.get_node("Portrait")
    adv_portrait = adv_textbox.get_node("Portrait")
    
    current_textbox = adv_textbox
    
    RenderingServer.canvas_item_set_z_index(adv_textbox.get_canvas_item(), 10)
    RenderingServer.canvas_item_set_z_index(chat_textbox.get_canvas_item(), 10)

## Returns whether the CutsceneInstance intends to advance the cutscene, based on user input.
static func should_advance_input():
    var custom = false
    if InputMap.action_get_events("cutscene_advance").size() > 0:
        custom = Input.is_action_just_pressed("cutscene_advance")
    return custom or Input.is_action_just_pressed("ui_accept")

## Returns whether the CutsceneInstance intends to skip animations, based on user input.
static func should_use_instant_text():
    var custom = false
    if InputMap.action_get_events("cutscene_instant_text").size() > 0:
        custom = Input.is_action_just_pressed("cutscene_instant_text")
    return custom or Input.is_action_pressed("ui_cancel")

## Returns whether the CutsceneInstance intends to make text come in instantly, based on user input.
static func should_skip_anims():
    var custom = false
    if InputMap.action_get_events("cutscene_skip").size() > 0:
        custom = Input.is_action_pressed("cutscene_skip")
    return custom or should_advance_input()

var _visible_characters : float = 0.0
var _skip_timer : float = 0.0
func _process(delta):
    var label = current_textbox.get_node("Label")
    if label.is_visible_in_tree() and current_textbox.modulate.a == 1.0:
        if CutsceneInstance.should_use_instant_text():
            _visible_characters = label.get_total_character_count()
        
        if _visible_characters >= 0.0 and _visible_characters < label.get_total_character_count():
            _visible_characters += delta * typein_speed
        
        if CutsceneInstance.should_skip_anims():
            _skip_timer += delta
        else:
            _skip_timer = 0.0
        
        var do_skip = _skip_timer > 1.0/skip_rate
        
        var do_continue = false
        
        if CutsceneInstance.should_advance_input() or do_skip:
            if do_skip:
                _visible_characters = label.get_total_character_count()
                do_continue = true
            elif _visible_characters >= 0.0 and _visible_characters < label.get_total_character_count():
                _visible_characters = label.get_total_character_count()
            else:
                do_continue = true
            _skip_timer = 0.0
        
        label.visible_characters = int(_visible_characters)
        
        adv_textbox.get_node("Nametag").visible_characters = -1
        chat_textbox.get_node("Nametag").visible_characters = -1
        
        if do_continue:
            if CutsceneInstance.should_advance_input():
                await Engine.get_main_loop().process_frame
            cutscene_continue.emit()
    else:
        label.visible_characters = 0
        adv_textbox.get_node("Nametag").visible_characters = 0
        chat_textbox.get_node("Nametag").visible_characters = 0
