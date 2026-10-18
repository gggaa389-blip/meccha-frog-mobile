extends Node

const APP_ID = 480
# [Mobile APK] Steam does not exist on phones: never init it there.
var steam_ready: bool = false
var player: Player = null
var pdata: Dictionary = {
	"username" = "steamuser99", 
	"cosmetics" = []
}

const version_url = "https://raw.githubusercontent.com/reckdave/crazycattle3d-steam-multiplayer/refs/heads/main/version.json"
const version = "2.0.0"
var version_release = "https://github.com/reckdave/crazycattle3d-steam-multiplayer/releases/tag/v"

func _on_version_check_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var data = str_to_var(body.get_string_from_utf8())
		if version < data["VERSION"]:
			OS.alert("THERE IS A NEW VERSION AVAILABLE!","HEY")
			OS.shell_open(version_release + data["VERSION"])


func update_checker():
	var http_request : HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_version_check_request_completed)
	http_request.request(version_url)

func _ready() -> void :
	# [Mobile APK] Skip Steam (and its blocking OS.alert) on mobile.
	if OS.has_feature("mobile") or OS.get_name() == "Android" or OS.get_name() == "iOS":
		print("[Mobile] Steam disabled on mobile")
		return
	Steam.steamInitEx(APP_ID)
	Steam.initRelayNetworkAccess()
	steam_ready = true

	var steam_open = Steam.loggedOn()
	if !steam_open:
		OS.alert("YOU DONT HAVE STEAM OPEN MEANING YOU WONT BE ABLE TO JOIN STEAM LOBBYS", "WARNING")
	else:
		print("steam is open")

func _process(_delta: float) -> void:
	# [Mobile APK] Only pump Steam callbacks after a desktop init.
	if steam_ready:
		Steam.run_callbacks()
