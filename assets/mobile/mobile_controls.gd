extends CanvasLayer
## [Mobile APK] Touch controls root. Built fully in code (no fragile .tscn):
## one full-rect surface that draws the joystick/buttons and handles
## multi-touch. Instantiated by player.gd only on Android/iOS and only
## for the local (multiplayer-authority) player.

const SurfaceScript := preload("res://assets/mobile/mobile_surface.gd")

var _surface: Control = null


func _init() -> void:
    name = "MobileControls"
    layer = 20


func _ready() -> void:
    _surface = SurfaceScript.new() as Control
    _surface.name = "MobileSurface"
    add_child(_surface)
    _surface.set_anchors_preset(Control.PRESET_FULL_RECT)


func set_player(p: Node) -> void:
    # Called right after instantiation, before/after _ready depending on
    # add order: forward now and again once the surface exists.
    if _surface != null and _surface.has_method("set_player"):
        _surface.call("set_player", p)
    else:
        await ready
        if _surface != null and _surface.has_method("set_player"):
            _surface.call("set_player", p)
