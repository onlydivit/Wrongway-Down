class_name GameAudio
extends AudioStreamPlayer

var music_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.stream = _ambient_loop()
	music_player.play()

func apply_settings(settings: Dictionary) -> void:
	var gain := 0.0 if settings.muted else float(settings.master)
	volume_linear = gain * float(settings.sfx)
	music_player.volume_linear = gain * float(settings.music)

func _ambient_loop() -> AudioStreamWAV:
	# An original, quiet eight-second arpeggio; integer cycles keep the loop smooth.
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 16000
	var count := 8 * wave.mix_rate
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var notes := [130.0, 164.0, 196.0, 246.0, 196.0, 164.0, 146.0, 196.0]
	for i in range(count):
		var t := float(i) / wave.mix_rate
		var beat := fposmod(t, 1.0)
		var envelope := sin(PI * beat) * 0.09
		var frequency: float = notes[int(t) % notes.size()]
		var sample := sin(TAU * frequency * t) * envelope + sin(TAU * 65.0 * t) * 0.025
		bytes.encode_s16(i * 2, int(sample * 32767))
	wave.data = bytes
	wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wave.loop_begin = 0
	wave.loop_end = count
	return wave

func _exit_tree() -> void:
	stop()
	stream = null
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null

func tone(frequency: float, duration: float) -> void:
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var count := int(duration * wave.mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var envelope := sin(PI * float(i) / count) * 0.15
		var sample := int(sin(TAU * frequency * float(i) / wave.mix_rate) * envelope * 32767)
		bytes.encode_s16(i * 2, sample)
	wave.data = bytes
	stream = wave
	play()
