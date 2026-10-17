class_name GameAudio
extends AudioStreamPlayer

func _exit_tree() -> void:
	stop()
	stream = null

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
