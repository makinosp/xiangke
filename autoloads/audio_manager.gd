## AudioManager autoload singleton.
## Manages audio playback with BGM/SFX bus separation, crossfade support,
## and Web Audio API autoplay initialization.
extends Node

## Audio track registry.
## Format: {track_id: {path: String, bus: String, volume: float, loop: bool}}
const AUDIO_REGISTRY: Dictionary = {
	# BGM tracks (looping)
	"bgm_main": {"path": "res://audio/bgm/main_theme.ogg", "bus": "bgm", "volume": 1.0, "loop": true},
	"bgm_battle": {"path": "res://audio/bgm/battle_theme.ogg", "bus": "bgm", "volume": 1.0, "loop": true},
	"bgm_title": {"path": "res://audio/bgm/title_theme.ogg", "bus": "bgm", "volume": 1.0, "loop": true},
	# SFX tracks (one-shot)
	"sfx_click": {"path": "res://audio/sfx/click.ogg", "bus": "sfx", "volume": 0.8, "loop": false},
	"sfx_hover": {"path": "res://audio/sfx/hover.ogg", "bus": "sfx", "volume": 0.6, "loop": false},
	"sfx_confirm": {"path": "res://audio/sfx/confirm.ogg", "bus": "sfx", "volume": 0.8, "loop": false},
	"sfx_cancel": {"path": "res://audio/sfx/cancel.ogg", "bus": "sfx", "volume": 0.7, "loop": false},
	"sfx_battle_start": {"path": "res://audio/sfx/battle_start.ogg", "bus": "sfx", "volume": 0.9, "loop": false},
	"sfx_victory": {"path": "res://audio/sfx/victory.ogg", "bus": "sfx", "volume": 0.9, "loop": false},
	"sfx_defeat": {"path": "res://audio/sfx/defeat.ogg", "bus": "sfx", "volume": 0.8, "loop": false},
}

# Bus names for AudioServer access.
const BUS_MASTER: String = "Master"
const BUS_BGM: String = "BGM"
const BUS_SFX: String = "SFX"

## Currently playing BGM track ID. Empty if none.
var current_bgm: String = ""
## Whether audio has been initialized (required for Web autoplay).
var audio_initialized: bool = false

## BGM AudioStreamPlayer node.
var bgm_player: AudioStreamPlayer
## SFX AudioStreamPlayer node.
var sfx_player: AudioStreamPlayer


func _ready() -> void:
	# Ensure audio buses exist (create if missing)
	_ensure_audio_buses()
	
	# Create audio player nodes since autoloads don't have scene children
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = BUS_BGM
	add_child(bgm_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = BUS_SFX
	add_child(sfx_player)

	_apply_save_volume()


## Ensures the required audio buses exist.
func _ensure_audio_buses() -> void:
	var master_idx := AudioServer.get_bus_index(BUS_MASTER)
	if master_idx < 0:
		# Master bus should always exist, but check anyway
		push_warning("AudioManager: Master bus not found")
		return
	
	# Check and add BGM bus if missing
	var bgm_idx := AudioServer.get_bus_index(BUS_BGM)
	if bgm_idx < 0:
		AudioServer.add_bus(master_idx + 1)
		bgm_idx = AudioServer.get_bus_index(BUS_BGM)
		if bgm_idx >= 0:
			AudioServer.set_bus_name(bgm_idx, BUS_BGM)
	
	# Check and add SFX bus if missing
	var sfx_idx := AudioServer.get_bus_index(BUS_SFX)
	if sfx_idx < 0:
		AudioServer.add_bus(master_idx + 1)
		sfx_idx = AudioServer.get_bus_index(BUS_SFX)
		if sfx_idx >= 0:
			AudioServer.set_bus_name(sfx_idx, BUS_SFX)


## Path to silent audio file for Web autoplay unlock.
const SILENT_AUDIO_PATH: String = "res://audio/silent.ogg"
const SILENT_AUDIO_FALLBACK: String = "res://audio/silent.wav"


## Initializes audio system.
## Must be called from a user interaction (click) to satisfy Web autoplay policy.
func initialize_audio() -> void:
	if audio_initialized:
		return

	# Play silent sound to unlock Web Audio API
	var silent_stream := load(SILENT_AUDIO_PATH) as AudioStream
	if silent_stream == null:
		silent_stream = load(SILENT_AUDIO_FALLBACK) as AudioStream
	
	if silent_stream != null:
		bgm_player.stream = silent_stream
		bgm_player.play()
		await bgm_player.finished
	else:
		# Fallback: create a silent AudioStreamGenerator
		var generator := AudioStreamGenerator.new()
		bgm_player.stream = generator
		bgm_player.play()
		await get_tree().create_timer(0.1).timeout
		bgm_player.stop()

	audio_initialized = true
	print("AudioManager: Audio initialized")


## Plays a BGM track with optional crossfade.
##
## Parameters:
##   track_id: ID of the track to play (must be in AUDIO_REGISTRY).
##   crossfade_duration: Seconds for crossfade transition (default 1.0).
func play_bgm(track_id: String, crossfade_duration: float = 1.0) -> void:
	if not audio_initialized:
		return
	if not AUDIO_REGISTRY.has(track_id):
		push_warning("AudioManager: Unknown BGM track: %s" % track_id)
		return
	if track_id == current_bgm:
		return # No-op if same track is already playing

	var track: Dictionary = AUDIO_REGISTRY[track_id]
	var stream := load(track.path) as AudioStream
	if stream == null:
		push_warning("AudioManager: Failed to load BGM: %s" % track.path)
		return

	# Crossfade: fade out current, fade in new
	var old_player := bgm_player
	if current_bgm.is_empty():
		# Direct play when no current BGM
		bgm_player.stream = stream
		_set_volume_db(bgm_player, BUS_BGM, track.volume)
		bgm_player.play()
	else:
		# Fade out old track
		var tween := create_tween()
		tween.tween_method(_set_player_volume.bind(bgm_player), bgm_player.volume_db, -80.0, crossfade_duration)
		await tween.finished
		bgm_player.stop()

		# Start new track
		bgm_player.stream = stream
		bgm_player.volume_db = -80.0
		bgm_player.play()

		# Fade in new track
		var fade_in := create_tween()
		fade_in.tween_method(_set_player_volume.bind(bgm_player), -80.0, _volume_to_db(track.volume), crossfade_duration)
		await fade_in.finished

	current_bgm = track_id


## Plays an SFX sound effect.
##
## Parameters:
##   track_id: ID of the track to play (must be in AUDIO_REGISTRY).
func play_sfx(track_id: String) -> void:
	if not audio_initialized:
		return
	if not AUDIO_REGISTRY.has(track_id):
		push_warning("AudioManager: Unknown SFX track: %s" % track_id)
		return

	var track: Dictionary = AUDIO_REGISTRY[track_id]
	var stream := load(track.path) as AudioStream
	if stream == null:
		push_warning("AudioManager: Failed to load SFX: %s" % track.path)
		return

	sfx_player.stream = stream
	_set_volume_db(sfx_player, BUS_SFX, track.volume)
	sfx_player.play()


## Stops the current BGM playback.
func stop_bgm() -> void:
	bgm_player.stop()
	current_bgm = ""


## Stops all audio playback.
func stop_all() -> void:
	bgm_player.stop()
	sfx_player.stop()
	current_bgm = ""


## Sets the master volume.
func set_master_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MASTER), _volume_to_db(value))


## Sets the BGM bus volume.
func set_bgm_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_BGM), _volume_to_db(value))


## Sets the SFX bus volume.
func set_sfx_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), _volume_to_db(value))


## Mutes/unmutes the master bus.
func set_master_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_MASTER), muted)


## Applies saved volume settings from SaveManager.
func _apply_save_volume() -> void:
	# Apply current save data immediately
	_on_save_loaded(SaveManager.current_data)
	
	# Connect to SaveManager signal to apply settings when save loads
	if SaveManager.save_loaded.is_connected(_on_save_loaded):
		return
	SaveManager.save_loaded.connect(_on_save_loaded)


## Handles save loaded signal to apply volume settings.
func _on_save_loaded(save_data: Dictionary) -> void:
	set_master_volume(save_data.get("master_volume", 1.0))
	set_bgm_volume(save_data.get("bgm_volume", 1.0))
	set_sfx_volume(save_data.get("sfx_volume", 1.0))
	set_master_muted(save_data.get("master_muted", false))


## Converts a linear volume value (0.0–1.0) to dB.
func _volume_to_db(value: float) -> float:
	return linear_to_db(clampf(value, 0.0, 1.0))


## Sets the volume on an AudioStreamPlayer using bus volume as reference.
func _set_volume_db(player: AudioStreamPlayer, bus_name: String, volume: float) -> void:
	player.volume_db = _volume_to_db(volume)


## Tween helper: sets player volume for crossfade.
## Used with tween_method where player is bound first, then value.
func _set_player_volume(value: float, player: AudioStreamPlayer) -> void:
	player.volume_db = value
