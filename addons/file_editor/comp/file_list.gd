@tool
extends "res://addons/file_editor/comp/base_filtered_list.gd"

const FOLDER_CLOSED := "🗀" # not visible in Godot.
const FOLDER_OPENED := "🗁" # not visible in Godot.

func _ready() -> void:
	super._ready()
	msg_no_items = "No folder opened"
	_ready_deferred.call_deferred()

func _ready_deferred():
	files.files_updated.connect(_refresh)
	files.settings_changed.connect(_refresh)
	editors.current_editor_changed.connect(_refresh)

func _refresh():
	items_updated()

func _process(delta: float) -> void:
	items.clear()
	for dir in files.get_children():
		_scan_dir(files, dir, items, 0)
	super._process(delta)

func _hover_started(meta: Variant):
	super._hover_started(meta)
	if meta is FE_File:
		set_hint(meta.path)

func _show_popup(meta: Variant):
	popup.clear()
	popup.add_options(meta.get_popup_options())

func _clicked(file: Variant):
	if Input.is_key_pressed(KEY_CTRL):
		file.open_in_file_list = not file.open_in_file_list
		items_updated()
		
	else:
		if file is FE_File:
			file.open()
		
		elif file is FE_Directory:
			file.open_in_file_list = not file.open_in_file_list
			items_updated()

var DARK := Color(.5, .5, .5, .5).to_html(false)
var YELL := Color.ORANGE.to_html(false)

func _draw_dir(dir: FE_Directory):
	var is_root := dir.get_parent() is FE_Files
	var dir_name := dir.path if is_root else dir.file_name
	if dir.open_in_file_list:
		var icon := "@"+FOLDER_OPENED if is_root else FOLDER_OPENED
		var c_name = YELL if is_root else Color.WHITE
		list.append_text("[color=#%s]▼[/color][color=#%s]%s[/color][color=#%s]｢[/color][color=#%s]%s[/color][color=#%s]｣[/color]" % [DARK, YELL, icon, DARK, c_name, dir_name, DARK])
	else:
		var icon := "@"+FOLDER_OPENED if is_root else FOLDER_CLOSED
		var c_name = YELL if is_root else Color.WHITE
		list.append_text("[color=#%s]▶[/color][color=#%s]%s[/color][color=#%s]｢[/color][color=#%s]%s[/color][color=#%s]｣[/color]" % [DARK, YELL, icon, DARK, c_name, dir_name, DARK])

func _draw_file(file: FE_File):
	var n = file.file_name.rsplit(".", true, 1)
	var ext: Dictionary = files.EXTENSIONS[n[1]]
	
	if file.is_open():
		list.push_color(ext.get("tint", DARK))
		list.append_text(ext.get("unicode", "🗎"))
		list.pop()
		
		if file.is_current():
			list.push_outline_size(4)
			list.push_outline_color(Color.YELLOW_GREEN.lightened(.25))
			list.push_color(Color.YELLOW_GREEN)
		else:
			list.push_outline_size(2)
			list.push_outline_color(Color.YELLOW_GREEN.darkened(.25))
			list.push_color(Color.YELLOW_GREEN)
		list.append_text(n[0])
		list.pop()
		list.pop()
		list.pop()
	else:
		list.push_color(DARK)
		list.append_text(ext.get("unicode", "🗎"))
		list.pop()
		
		list.append_text(n[0])
	
	list.push_color(DARK)
	list.add_text("." + n[1])
	list.pop()

func _post_draw_item(item: Dictionary):
	if item.meta is FE_File and item.meta.open_in_file_list:
		for line in item.meta.chapters:
			var chapter = item.meta.chapters[line]
			_push_item(
				TAB.repeat(item.deep) + " [color=#%s]%s%s[/color]" % [DARK, TAB.repeat(chapter.deep-1), chapter.name],
				item.meta.open.bind(line))

func _show_files(dir: FE_Directory) -> bool:
	return dir.open_in_file_list or filter_text != ""

func _scan_dir(files: FE_Files, dir: FE_Directory, parent: Array, indent: int):
	var item := {
		text=dir.file_name,
		draw=_draw_dir.bind(dir),
		show_children=_show_files.bind(dir),
		meta=dir,
		deep=indent,
		children=[]
	}
	parent.append(item)
	
	for file in dir.get_children():
		if not files.is_visible(file):
#			print("HIDE ", file.path)
			continue
			
		if file is FE_File:
			item.children.append({
				text=file.file_name,
				draw=_draw_file.bind(file),
				meta=file,
				deep=indent+1
			})
		elif file is FE_Directory:
#			if not files.show_dir_empty and file.is_empty():
#				continue
			
			_scan_dir(files, file, item.children, indent+1)
