class_name SfxPlayer
extends Node
## Tiny procedural sound kit — no external audio assets needed.

const RATE := 22050
const PLAYERS := 8

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	_build_streams()
	for i in PLAYERS:
		var player := AudioStreamPlayer.new()
		player.volume_db = -3.0
		add_child(player)
		_players.append(player)


func play(sound: String, pitch := 1.0) -> void:
	if Profile.muted or not _streams.has(sound):
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _streams[sound]
	player.pitch_scale = pitch
	player.play()


func _build_streams() -> void:
	_streams["place"] = _build([
		{"at": 0.0, "dur": 0.11, "f0": 170.0, "f1": 90.0, "wave": "sine", "vol": 0.55},
		{"at": 0.0, "dur": 0.035, "f0": 400.0, "f1": 200.0, "wave": "noise", "vol": 0.16},
	])
	_streams["clear"] = _build([
		{"at": 0.00, "dur": 0.20, "f0": 523.25, "f1": 523.25, "wave": "triangle", "vol": 0.24},
		{"at": 0.055, "dur": 0.20, "f0": 659.25, "f1": 659.25, "wave": "triangle", "vol": 0.24},
		{"at": 0.11, "dur": 0.22, "f0": 783.99, "f1": 783.99, "wave": "triangle", "vol": 0.22},
		{"at": 0.17, "dur": 0.34, "f0": 1046.5, "f1": 1046.5, "wave": "sine", "vol": 0.20},
	])
	_streams["awaken"] = _build([
		{"at": 0.0, "dur": 0.55, "f0": 120.0, "f1": 320.0, "wave": "sine", "vol": 0.26},
		{"at": 0.0, "dur": 0.55, "f0": 0.0, "f1": 0.0, "wave": "noise", "vol": 0.14},
		{"at": 0.22, "dur": 0.4, "f0": 440.0, "f1": 660.0, "wave": "triangle", "vol": 0.10},
	])
	_streams["obsidian"] = _build([
		{"at": 0.0, "dur": 0.30, "f0": 640.0, "f1": 920.0, "wave": "sine", "vol": 0.24},
		{"at": 0.02, "dur": 0.18, "f0": 1280.0, "f1": 1560.0, "wave": "triangle", "vol": 0.10},
	])
	_streams["dissolve"] = _build([
		{"at": 0.0, "dur": 0.24, "f0": 0.0, "f1": 0.0, "wave": "noise", "vol": 0.20},
		{"at": 0.0, "dur": 0.18, "f0": 220.0, "f1": 120.0, "wave": "sine", "vol": 0.14},
	])
	_streams["invalid"] = _build([
		{"at": 0.0, "dur": 0.12, "f0": 130.0, "f1": 85.0, "wave": "square", "vol": 0.18},
	])
	_streams["ui"] = _build([
		{"at": 0.0, "dur": 0.05, "f0": 660.0, "f1": 760.0, "wave": "sine", "vol": 0.12},
	])
	_streams["game_over"] = _build([
		{"at": 0.00, "dur": 0.28, "f0": 392.0, "f1": 392.0, "wave": "triangle", "vol": 0.18},
		{"at": 0.16, "dur": 0.28, "f0": 329.6, "f1": 329.6, "wave": "triangle", "vol": 0.18},
		{"at": 0.32, "dur": 0.52, "f0": 261.6, "f1": 196.0, "wave": "sine", "vol": 0.20},
	])
	_streams["pickup"] = _build([
		{"at": 0.0, "dur": 0.06, "f0": 560.0, "f1": 820.0, "wave": "sine", "vol": 0.10},
	])
	_streams["surge"] = _build([
		{"at": 0.0, "dur": 0.55, "f0": 0.0, "f1": 0.0, "wave": "noise", "vol": 0.16},
		{"at": 0.0, "dur": 0.5, "f0": 80.0, "f1": 160.0, "wave": "sine", "vol": 0.16},
		{"at": 0.18, "dur": 0.25, "f0": 330.0, "f1": 440.0, "wave": "triangle", "vol": 0.08},
	])
	_streams["crystallize"] = _build([
		{"at": 0.00, "dur": 0.28, "f0": 659.3, "f1": 659.3, "wave": "triangle", "vol": 0.16},
		{"at": 0.06, "dur": 0.28, "f0": 880.0, "f1": 880.0, "wave": "triangle", "vol": 0.14},
		{"at": 0.12, "dur": 0.38, "f0": 1174.7, "f1": 1174.7, "wave": "sine", "vol": 0.12},
	])
	_streams["combo"] = _build([
		{"at": 0.00, "dur": 0.18, "f0": 659.3, "f1": 659.3, "wave": "triangle", "vol": 0.22},
		{"at": 0.05, "dur": 0.18, "f0": 880.0, "f1": 880.0, "wave": "triangle", "vol": 0.22},
		{"at": 0.10, "dur": 0.22, "f0": 1046.5, "f1": 1046.5, "wave": "triangle", "vol": 0.20},
		{"at": 0.16, "dur": 0.34, "f0": 1318.5, "f1": 1318.5, "wave": "sine", "vol": 0.18},
	])
	_streams["heat"] = _build([
		{"at": 0.0, "dur": 0.55, "f0": 0.0, "f1": 0.0, "wave": "noise", "vol": 0.13},
		{"at": 0.0, "dur": 0.55, "f0": 90.0, "f1": 165.0, "wave": "sine", "vol": 0.14},
		{"at": 0.16, "dur": 0.4, "f0": 220.0, "f1": 330.0, "wave": "triangle", "vol": 0.07},
	])
	_streams["cold"] = _build([
		{"at": 0.00, "dur": 0.25, "f0": 1046.5, "f1": 1046.5, "wave": "triangle", "vol": 0.12},
		{"at": 0.06, "dur": 0.28, "f0": 1318.5, "f1": 1318.5, "wave": "sine", "vol": 0.10},
		{"at": 0.12, "dur": 0.42, "f0": 1568.0, "f1": 1568.0, "wave": "sine", "vol": 0.08},
		{"at": 0.0, "dur": 0.3, "f0": 0.0, "f1": 0.0, "wave": "noise", "vol": 0.05},
	])


func _build(notes: Array) -> AudioStreamWAV:
	var duration := 0.02
	for note in notes:
		duration = maxf(duration, float(note["at"]) + float(note["dur"]))

	var count := int(duration * RATE) + 1
	var mix := PackedFloat32Array()
	mix.resize(count)

	for note in notes:
		var start := int(float(note["at"]) * RATE)
		var length := int(float(note["dur"]) * RATE)
		var wave := str(note["wave"])
		var f0 := float(note["f0"])
		var f1 := float(note["f1"])
		var volume := float(note["vol"])
		var phase := 0.0
		var noise_low := 0.0

		for i in length:
			var index := start + i
			if index >= count:
				break
			var t := float(i) / float(maxi(length - 1, 1))
			var sample := 0.0
			if wave == "noise":
				noise_low = noise_low * 0.72 + randf_range(-1.0, 1.0) * 0.28
				sample = noise_low
			else:
				var freq := lerpf(f0, f1, t)
				phase += TAU * freq / float(RATE)
				if wave == "triangle":
					sample = 2.0 / PI * asin(sin(phase))
				elif wave == "square":
					sample = 0.55 if sin(phase) >= 0.0 else -0.55
				else:
					sample = sin(phase)
			var attack := minf(1.0, float(i) / (0.005 * float(RATE)))
			var envelope := attack * pow(1.0 - t, 2.0)
			mix[index] += sample * envelope * volume

	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var value := clampf(mix[i], -1.0, 1.0) * 0.85
		bytes.encode_s16(i * 2, int(value * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return stream
