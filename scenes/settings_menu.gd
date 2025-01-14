extends CanvasLayer

signal back_button_pressed

var selectedResolution := "3840 X 2160"
var selectedViewportMode := "Fullscreen"
var selectedVolume := 0.0

var config = ConfigFile.new()

func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func apply_settings():
	_on_apply_button_pressed()

func _on_apply_button_pressed():
	# set resolution:
	var sizes = selectedResolution.split(" X ", false, 2)
	get_window().size = Vector2i(int(sizes[0]), int(sizes[1]))
	
	# set windowMode
	var windowMode = Window.MODE_EXCLUSIVE_FULLSCREEN
	match selectedViewportMode:
		"Maximized":
			windowMode = Window.MODE_MAXIMIZED
		"Minimized":
			windowMode = Window.MODE_MINIMIZED
		"Windowed":
			windowMode = Window.MODE_WINDOWED
		"Fullscreen":
			windowMode = Window.MODE_FULLSCREEN
		"Exclusive Fullscreen":
			windowMode = Window.MODE_EXCLUSIVE_FULLSCREEN
	get_tree().root.mode = windowMode
	
	# set master volume:
	var master_index := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_index, selectedVolume)
	
	save_config(selectedResolution, selectedViewportMode, selectedVolume)
	
func save_config(resolution, viewport_mode, master_volume):
	config.set_value("Settings", "resolution", resolution)
	config.set_value("Settings", "viewport_mode", viewport_mode)
	config.set_value("Settings", "master_volume", master_volume)
	config.save("./settings.cfg")
	
func load_settings():
	var err = config.load("./settings.cfg")
	if err != OK:
		print("failed to load settings from settings.cfg.\nDoes it exist?")
		return

	# retrieve the settings from the config file
	for setting in config.get_sections():
		selectedResolution = config.get_value("Settings", "resolution")
		selectedViewportMode = config.get_value("Settings", "viewport_mode")
		selectedVolume = config.get_value("Settings", "master_volume")

	# next find the index of what they are and set them with this:
	$ResolutionOptions.select(0)
	$ViewportOptions.select(0)
	for i in $ResolutionOptions.item_count:
		if $ResolutionOptions.get_item_text(i) == selectedResolution:
			$ResolutionOptions.select(i)
	for i in $ViewportOptions.item_count:
		if $ViewportOptions.get_item_text(i) == selectedViewportMode:
			$ViewportOptions.select(i)
	$VolumeSlider.value = selectedVolume

func _on_resolution_options_item_selected(index):
	selectedResolution = $ResolutionOptions.get_item_text(index)

func _on_viewport_mode_options_item_selected(index):
	selectedViewportMode = $ViewportOptions.get_item_text(index)

func _on_back_button_pressed():
	back_button_pressed.emit()
	
# this grabs the focus when we switch to this scene
func take_focus():
	$ReferenceRect/ApplyButton.grab_focus()

func _on_volume_slider_value_changed(value):
	selectedVolume = $VolumeSlider.value
