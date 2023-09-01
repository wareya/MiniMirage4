extends RefCounted

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        print("deleting cutscene!!!!!!!!!!")

func mini_demo_cutscene(cutscene : CutsceneInstance):
    var bg_texture = load("res://minimirage/art/test_bg.jpg")
    var tachie = load("res://minimirage/art/tachie/vn engine test tachie base.png")
    
    var bg_image = cutscene.add_background(bg_texture)
    await bg_image.fade_show()
    
    var image = cutscene.add_tachie(tachie)
    await image.fade_show()
    
    cutscene.set_nametag("Guide")
    
    await cutscene.set_text("Hello, world!")
    
    cutscene.finish()

func demo_cutscene(cutscene : CutsceneInstance):
    var bg_texture = load("res://minimirage/art/test_bg.jpg")
    
    var tachie_a = load("res://minimirage/art/tachie/vn engine test tachie base.png")
    var tachie_b = load("res://minimirage/art/tachie/vn engine test tachie confident.png")
    var tachie_c = load("res://minimirage/art/tachie/vn engine test tachie really.png")
    
    var face_a = load("res://minimirage/art/tachie/vn engine test face base.png")
    var face_b = load("res://minimirage/art/tachie/vn engine test face confident.png")
    var face_c = load("res://minimirage/art/tachie/vn engine test face really.png")
    
    var bg_image = cutscene.add_background(bg_texture)
    
    print("showing bg")
    await bg_image.fade_show()
    print("and it's done")
    
    await cutscene.set_text("Something approaches.")
    
    cutscene.set_nametag("???")
    
    await cutscene.set_text("Wow! What is that?")
    
    cutscene.clear_text()
    cutscene.set_nametag("Guide")
    
    var image = cutscene.add_tachie(tachie_a)
    cutscene.adv_set_face(face_a)
    image.set_new_position(Vector2(-0.5, 0.0))
    
    await image.fade_show()
    
    await cutscene.set_text("Wait, it's not...? It can't be!")
    
    cutscene.clear_text()
    image.set_new_texture(tachie_b)
    image.set_new_scale(Vector2(-1.2, 1.2))
    cutscene.adv_set_face(face_b)
    
    await image.smooth_position(Vector2(0.0, 0.0))
    
    await cutscene.set_text("Oh my god, why didn't you tell me about this!")
    
    cutscene.textbox_set_chat(Vector2(0.05, -0.4))
    
    await cutscene.set_text("This... This is good.")
    
    image.set_texture(tachie_c)
    cutscene.adv_set_face(face_c)
    
    await cutscene.set_text("But you know—this isn't all there is to see in life.")
    
    cutscene.clear_text()
    
    await cutscene.textbox_hide()
    
    image.set_new_texture(tachie_a)
    cutscene.adv_set_face(face_a)
    
    await image.smooth_scale(Vector2(-1.0, 1.0))
    
    await image.smooth_position(Vector2(0.3, 0.0))
    
    image.set_new_scale(Vector2(1.0, 1.0))
    cutscene.textbox_set_chat(Vector2(0.3, -0.35), "upright")
    
    await cutscene.set_text("You need to stop and smell the roses. Listen to the music. Help out a friend or two. That kind of thing.")
    
    await cutscene.textbox_hide()
    
    await image.fade_hide()
    
    cutscene.textbox_set_chat(Vector2(0.5, 0.3), "downright")
    cutscene.chat_set_face(face_a)
    
    await cutscene.set_text("I'll be off, now!")
    
    cutscene.chat_set_face(face_b, true)
    
    await cutscene.set_text("Take care!")
    
    # Always call this at the end of the cutscene.
    cutscene.finish()
