extends Control


func _ready():
    await Engine.get_main_loop().process_frame
    await Engine.get_main_loop().process_frame
    
    # start cutscene (it loops)
    start_cutscene()

func start_cutscene():
    print("Starting cutscene...")
    
    var cutscene = CutsceneStarter.load_and_start_cutscene("res://DemoCutsceneStandalone.gd", "demo_cutscene")
    # or:
    #var cutscene = CutsceneStarter.start_cutscene(preload("res://DemoCutsceneStandalone.gd").new().demo_cutscene)
    await cutscene.cutscene_finished
    
    print("Cutscene finished!")
    
    # start cutscene over
    await get_tree().create_timer(1.0).timeout
    call_deferred("start_cutscene")
