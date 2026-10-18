extends Control
## [Mobile APK] Full-screen multi-touch surface.
## One touch index = joystick OR camera OR one button.
## Buttons send a real InputEventAction (Input.parse_input_event), so code
## that checks events in _input() works exactly like a keyboard/mouse press.
## Movement axes use Input.action_press() with strength (polled in physics).

const DEADZONE := 0.18
const JOY_RADIUS := 82.0
const JOY_KNOB := 32.0
const JOY_TOUCH_DIST := 180.0

var player: Node = null

var _joy_id := -1
var _joy_vector := Vector2.ZERO
var _joy_knob_offset := Vector2.ZERO
var _cam_id := -1
var _cam_last := Vector2.ZERO
var _button_by_touch: Dictionary = {}
var _pressed: Dictionary = {}
var _was_blocked := false


func _ready() -> void:
    # IGNORE: never block taps meant for menus / ColorPicker below us.
    # We still receive _input() for every touch.
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_preset(Control.PRESET_FULL_RECT)
    if get_viewport() != null:
        get_viewport().size_changed.connect(queue_redraw)


func set_player(p: Node) -> void:
    player = p


func _exit_tree() -> void:
    _release_all()


func _process(_delta: float) -> void:
    # When a menu/paint UI takes over, stop driving the character.
    var blocked := _pause_open() or _painting()
    if blocked and not _was_blocked:
        _release_gameplay()
    if blocked != _was_blocked:
        _was_blocked = blocked
        queue_redraw()


# ---------------------------------------------------------------- layout

func _rect_size() -> Vector2:
    if size.x > 10.0 and size.y > 10.0:
        return size
    return get_viewport_rect().size


func _joy_center() -> Vector2:
    var s := _rect_size()
    return Vector2(165.0, s.y - 165.0)


func _painting() -> bool:
    return player != null and bool(player.get("paint_on"))


func _pause_open() -> bool:
    if player == null:
        return false
    var pm := player.get_node_or_null("UI/PauseMenu")
    return pm != null and (pm as CanvasItem).visible


func _buttons() -> Array:
    var s := _rect_size()
    if _painting():
        # ColorPicker occupies the top-left (300x634): keep DONE top-centre.
        return [{
            "action": "paint_mode", "label": "DONE",
            "center": Vector2(s.x * 0.5, 68.0), "radius": 42.0,
            "color": Color(0.15, 0.75, 0.45, 0.60),
        }]
    if _pause_open():
        # PauseMenu has no resume button in the original game (Esc toggles
        # it), so the pause button must stay reachable above the menu.
        return [{
            "action": "escape", "label": "| |",
            "center": Vector2(s.x - 64.0, 64.0), "radius": 38.0,
            "color": Color(0.35, 0.40, 0.50, 0.60),
        }]
    return [
        {"action": "paint_mode", "label": "PAINT", "center": Vector2(86.0, 72.0), "radius": 40.0, "color": Color(0.15, 0.75, 0.45, 0.55)},
        {"action": "talkie", "label": "TALK", "center": Vector2(198.0, 72.0), "radius": 40.0, "color": Color(0.95, 0.55, 0.15, 0.55)},
        {"action": "escape", "label": "| |", "center": Vector2(s.x - 64.0, 64.0), "radius": 38.0, "color": Color(0.35, 0.40, 0.50, 0.55)},
        {"action": "run", "label": "RUN", "center": Vector2(s.x - 270.0, s.y - 255.0), "radius": 42.0, "color": Color(0.95, 0.55, 0.15, 0.55)},
        {"action": "jump", "label": "JUMP", "center": Vector2(s.x - 120.0, s.y - 295.0), "radius": 47.0, "color": Color(0.20, 0.55, 0.95, 0.55)},
        {"action": "action", "label": "USE", "center": Vector2(s.x - 275.0, s.y - 112.0), "radius": 46.0, "color": Color(0.20, 0.80, 0.35, 0.55)},
        {"action": "fire", "label": "FIRE", "center": Vector2(s.x - 124.0, s.y - 142.0), "radius": 57.0, "color": Color(0.90, 0.20, 0.20, 0.60)},
    ]


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var t := event as InputEventScreenTouch
        if t.pressed:
            _on_touch_pressed(t.index, t.position)
        else:
            _on_touch_released(t.index)
    elif event is InputEventScreenDrag:
        var d := event as InputEventScreenDrag
        _on_drag(d.index, d.position, d.relative)


func _on_touch_pressed(index: int, pos: Vector2) -> void:
    # Buttons have priority over joystick/camera.
    for b in _buttons():
        var center: Vector2 = b["center"]
        var radius: float = b["radius"]
        if pos.distance_to(center) <= radius + 10.0:
            var action := String(b["action"])
            _button_by_touch[index] = action
            _pressed[action] = true
            _send_action(action, true)
            Input.vibrate_handheld(15)
            queue_redraw()
            return
    if _painting() or _pause_open():
        return
    if _joy_id == -1 and pos.distance_to(_joy_center()) <= JOY_TOUCH_DIST:
        _joy_id = index
        _update_joy(pos)
        return
    if _cam_id == -1:
        _cam_id = index
        _cam_last = pos


func _on_touch_released(index: int) -> void:
    if _button_by_touch.has(index):
        var action := String(_button_by_touch[index])
        _button_by_touch.erase(index)
        if not _button_by_touch.values().has(action):
            _pressed[action] = false
            _send_action(action, false)
        queue_redraw()
    if index == _joy_id:
        _joy_id = -1
        _joy_vector = Vector2.ZERO
        _joy_knob_offset = Vector2.ZERO
        _apply_axes()
        queue_redraw()
    if index == _cam_id:
        _cam_id = -1


func _on_drag(index: int, pos: Vector2, relative: Vector2) -> void:
    if index == _joy_id:
        _update_joy(pos)
    elif index == _cam_id:
        var delta := relative
        if delta == Vector2.ZERO:
            delta = pos - _cam_last
        _cam_last = pos
        if delta != Vector2.ZERO and player != null and player.has_method("mobile_look"):
            player.call("mobile_look", delta)


func _update_joy(pos: Vector2) -> void:
    var v := pos - _joy_center()
    if v.length() > JOY_RADIUS:
        v = v.normalized() * JOY_RADIUS
    _joy_knob_offset = v
    var n := v / JOY_RADIUS
    if n.length() < DEADZONE:
        n = Vector2.ZERO
    _joy_vector = n
    _apply_axes()
    queue_redraw()


func _apply_axes() -> void:
    _axis(&"forward", clampf(-_joy_vector.y, 0.0, 1.0))
    _axis(&"backwards", clampf(_joy_vector.y, 0.0, 1.0))
    _axis(&"left", clampf(-_joy_vector.x, 0.0, 1.0))
    _axis(&"right", clampf(_joy_vector.x, 0.0, 1.0))


func _axis(action: StringName, strength: float) -> void:
    if strength > DEADZONE:
        Input.action_press(action, strength)
    else:
        Input.action_release(action)


func _send_action(action: String, pressed: bool) -> void:
    var ev := InputEventAction.new()
    ev.action = StringName(action)
    ev.pressed = pressed
    ev.strength = 1.0 if pressed else 0.0
    Input.parse_input_event(ev)


func _release_gameplay() -> void:
    _joy_id = -1
    _cam_id = -1
    _joy_vector = Vector2.ZERO
    _joy_knob_offset = Vector2.ZERO
    _apply_axes()
    # Keep button touches: the visible DONE / pause button must still work.


func _release_all() -> void:
    for index in _button_by_touch.keys():
        _send_action(String(_button_by_touch[index]), false)
    _button_by_touch.clear()
    _pressed.clear()
    _release_gameplay()


# ---------------------------------------------------------------- draw

func _draw() -> void:
    var s := _rect_size()
    if s.x < 10.0 or s.y < 10.0:
        return
    var font := get_theme_default_font()
    if not _painting() and not _pause_open():
        var c := _joy_center()
        draw_circle(c, JOY_RADIUS, Color(1, 1, 1, 0.13))
        draw_arc(c, JOY_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.45), 3.0)
        draw_circle(c + _joy_knob_offset, JOY_KNOB, Color(1, 1, 1, 0.72))
    for b in _buttons():
        var center: Vector2 = b["center"]
        var radius: float = b["radius"]
        var col: Color = b["color"]
        var action := String(b["action"])
        if bool(_pressed.get(action, false)):
            col.a = 0.92
        draw_circle(center, radius, col)
        draw_arc(center, radius, 0.0, TAU, 44, Color(1, 1, 1, 0.60), 2.5)
        var label := String(b["label"])
        var fsize := 20 if radius >= 44.0 else 17
        var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fsize)
        var baseline := center + Vector2(-text_size.x * 0.5, float(fsize) * 0.35)
        draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fsize, Color.WHITE)
