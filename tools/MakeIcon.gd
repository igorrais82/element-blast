extends SceneTree
## Renders the project SVG icon into docs/icon.png and builds assets/icon.ico.
## Run: godot --headless --path . --script res://tools/MakeIcon.gd

const ICO_SIZES := [256, 128, 64, 48, 32, 16]


func _initialize() -> void:
	var texture: Texture2D = load("res://assets/icon.svg")
	if texture == null:
		print("Cannot load icon.svg")
		quit(1)
		return
	var image := texture.get_image()
	if image == null:
		print("Cannot read icon image")
		quit(1)
		return

	var preview := image.duplicate() as Image
	preview.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	preview.save_png("res://docs/icon.png")
	print("docs/icon.png")

	var frames: Array[PackedByteArray] = []
	for icon_size in ICO_SIZES:
		var copy := image.duplicate() as Image
		copy.resize(icon_size, icon_size, Image.INTERPOLATE_LANCZOS)
		frames.append(copy.save_png_to_buffer())
		print("icon frame %d" % icon_size)

	var ico := _build_ico(frames)
	var file := FileAccess.open("res://assets/icon.ico", FileAccess.WRITE)
	if file == null:
		print("Cannot write icon.ico")
		quit(1)
		return
	file.store_buffer(ico)
	file.close()
	print("assets/icon.ico (%d bytes)" % ico.size())
	quit(0)


func _build_ico(frames: Array[PackedByteArray]) -> PackedByteArray:
	var count := frames.size()
	var data := PackedByteArray()
	data.resize(6 + 16 * count)

	data.encode_u16(0, 0)
	data.encode_u16(2, 1)
	data.encode_u16(4, count)

	var offset := 6 + 16 * count
	for i in count:
		var icon_size: int = ICO_SIZES[i]
		var png: PackedByteArray = frames[i]
		var pos := 6 + 16 * i
		var dimension := 0 if icon_size >= 256 else icon_size
		data.encode_u8(pos, dimension)
		data.encode_u8(pos + 1, dimension)
		data.encode_u8(pos + 2, 0)
		data.encode_u8(pos + 3, 0)
		data.encode_u16(pos + 4, 1)
		data.encode_u16(pos + 6, 32)
		data.encode_u32(pos + 8, png.size())
		data.encode_u32(pos + 12, offset)
		offset += png.size()

	for png in frames:
		data.append_array(png)
	return data
