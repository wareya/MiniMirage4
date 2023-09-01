class_name CutsceneStarter

## Starts a cutscene function (from a script file) with a new CutsceneInstance.
## [br]
## Returns the new CutsceneInstance to control the new cutscene.
static func load_and_start_cutscene(filename : String, function_name : String):
    # create a CutsceneInstance to keep track of the cutscene and add it to the scene
    var cutscene = CutsceneInstance.new()
    Engine.get_main_loop().current_scene.add_child(cutscene)
    print("added cutsceneinstance to world")
    
    # load the object
    var obj = load(filename).new() as Object
    
    # put the object in the world if it's a Node, so that it doesn't leak memory
    # we make it a child of the CutsceneInstance so that it automatically cleans up
    if obj is Node and !obj.is_inside_tree():
        cutscene.add_child(obj)
    
    # start the cutscene with the CutsceneInstance as its argument
    if obj is RefCounted:
        var callable = obj.call.bind(function_name, cutscene)
        _refcount_holder(obj, callable)
    else:
        obj.call(function_name, cutscene)
    
    return cutscene
    
    # on your end: wait for the cutscene to finish
    #yield(cutscene, "cutscene_finished")

## Starts a callable with a new CutsceneInstance.
## [br]
## Returns the new CutsceneInstance to control the new cutscene.
static func start_cutscene(callable : Callable):
    # create a CutsceneInstance to keep track of the cutscene and add it to the scene
    var cutscene = CutsceneInstance.new()
    Engine.get_main_loop().current_scene.add_child(cutscene)
    print("added cutsceneinstance to world 2")
    
    var obj = callable.get_object()
    
    # start the cutscene with the CutsceneInstance as its argument
    if obj is RefCounted:
        callable = callable.bind(cutscene)
        _refcount_holder(obj, callable)
    else:
        callable.call(cutscene)
    
    return cutscene
    
    # on your end: wait for the cutscene to finish
    #yield(cutscene, "cutscene_finished")

# used internally to work around a godot 4.0/4.1 bug:
# https://github.com/godotengine/godot/issues/81210
static func _refcount_holder(refcount : RefCounted, callable : Callable):
    var temp = refcount
    await callable.call()
