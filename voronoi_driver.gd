extends MeshInstance

var points
func _ready():
	points = create_points(100)
	randomize()
	for d in points:
		# give each point a random, blueish color and a random speed
		d.set_color(
			Color.from_hsv(0.5, rand_range(0.0, 1.0),
			rand_range(0.0, 1.0))) \
			.set_speed(rand_range(0.01, 0.2))

func _process(delta):
	for point in points:
		point.move(delta)

func create_points(count):
	var tex = ImageTexture.new()
	var img = Image.new()
	
	# COLOR SPACE MATTERS!
	# If you have the wrong color space, 0.5 0.5 won't be in the middle, it'll be
	# shifted on a logarithmic scale to the top left! (or just won't be there, depending
	# on color space.
	# See https://docs.godotengine.org/en/stable/classes/class_image.html
	# and check the list. They're actually pretty simple -
	# FORMAT_RGBA4444 - 4 4bit floats
	# FORMAT_RF - 1 32bit float
	# FORMAT_RGF - 2 32bit floats
	# FORMAT_RGBF - 3 32bit floats
	# FORMAT_RGBAF - 4 32bit floats
	# there's also some for 16bit or 9bit if you're weird
	img.create(count, 2, false, Image.FORMAT_RGBF)
	
	var new_points = []
	for i in range(count):
		var new_point = VoronoiPoint.new()
		new_point.img = img
		new_point.tex = tex
		new_point.idx = i
		new_point.mi = self
		new_point.update_texture()
		new_points.append(new_point)
	
	return new_points


class VoronoiPoint:
	var speed     = 0.1
	var direction = Vector2(0.0, 0.0)
	var position  = Vector2(0.0, 0.0)
	var color     = Color.blueviolet
	var mi
	var tex
	var idx
	var img
	
	func _init():
		position = Vector2(rand_range(0.0, 1.0), rand_range(0.0, 1.0))
		direction = Vector2(rand_range(-1.0, 1.0), rand_range(-1.0, 1.0))
	
	func move(delta):
		# every frame, move the points around, such that they bounce off
		# the edges of the mesh
		var prev = position
		var velo = direction * speed * delta
		if velo != Vector2.ZERO:
			position += velo
			if position.x > 1:
				position.x = 1
				direction.x = -direction.x
				
			if position.x < 0:
				position.x = 0
				direction.x = -direction.x
				
			if position.y > 1:
				position.y = 1
				direction.y = -direction.y
				
			if position.y < 0:
				position.y = 0
				direction.y = -direction.y
			update_texture()
			
	func update_texture():
		img.lock()
		img.set_pixel(idx, 0, Color(position.x, position.y, 0, 0))
		img.set_pixel(idx, 1, color)
		img.unlock()
		# for debugging, the texture encoding all the point's xyzrgb values
		# can be written to a file
		# img.save_png("input_texture.png")
		tex.create_from_image(img)
		# in theory, this should be batch each frame instead
		# of set each time a point is updated
		mi.get_surface_material(0).set_shader_param("points", tex)

	func set_color(new_color):
		color = new_color
		update_texture()
		return self

	func set_speed(new_speed):
		speed = new_speed
		return self

	func set_position(x, y):
		position = Vector2(x, y)
		update_texture()
		return self
