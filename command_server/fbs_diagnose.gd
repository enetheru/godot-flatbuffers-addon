@tool
extends CommandServerTool

## Open a FlatBuffers schema and read the issues the highlighter stored.
##
## The script-editor tab is closed first. The next open builds a new highlighter,
## so the issues belong to this pass. ScriptEditor.open_file() is not bound to
## GDScript. The FileSystem dock's item_activated handler is the path EditorNode
## uses for text files, including .fbs once it is in
## docks/filesystem/textfile_extensions. The plugin leaves that setting
## alone. Writing it hangs the editor. See Notes/EditorSettings.md.
##
## Highlighting parses a line when Godot draws it. The new tab is read after
## the next paint.

const Log = preload( "uid://biv0hwe68jj3s" )


func get_command_name() -> String:
	return "FBS_DIAGNOSE"


func get_description() -> String:
	return "Open a .fbs schema and report the syntax issues the highlighter has stored. An optional inclusive level reparses the file at that ceiling and returns those log lines. DEBUG and TRACE also include the parser stack for each issue."


func get_usage() -> String:
	return "FBS_DIAGNOSE <res://path.fbs> [SILENT|CRITICAL|ERROR|WARNING|NOTICE|INFO|DEBUG|TRACE]"


func get_input_schema() -> Dictionary:
	return {
		"type": "object",
		"properties": {
			"path": {
				"type": "string",
				"description": "res:// or user:// path to a .fbs schema",
			},
			"level": {
				"type": "string",
				"description": "Inclusive log ceiling. DEBUG and TRACE include the parser stack. Omit for the issue list only.",
			},
		},
		"required": ["path"],
		"additionalProperties": false,
	}


func arguments_from_line( line:String, _tail:String ) -> Dictionary:
	var text:String = line.strip_edges()
	var out:Dictionary = { &"path": text }
	var pieces:PackedStringArray = text.split( " ", false )
	if pieces.size() >= 2 and _looks_like_level( pieces[pieces.size() - 1] ):
		out[&"level"] = pieces[pieces.size() - 1]
		var path_parts:PackedStringArray = pieces.slice( 0, pieces.size() - 1 )
		out[&"path"] = " ".join( path_parts )
	return out


var _paint_on_done:Callable = Callable()
var _paint_path:String = ""
var _paint_level:int = -1
var _in_flight:bool = false


func begin_execute(
		arguments:Dictionary,
		_context:Dictionary,
		on_done:Callable
) -> void:
	if _in_flight:
		if on_done.is_valid():
			on_done.call( result_from_text( "ERROR: FBS_DIAGNOSE busy" ) )
		return
	var resolved:Dictionary = _resolve_level( arguments )
	if resolved.has( &"error" ):
		if on_done.is_valid():
			on_done.call( result_from_text( str( resolved[&"error"] ) ) )
		return
	var level:int = _narrow_int( resolved[&"level"] )
	var prepared:Dictionary = _prepare( path_line_from_arguments( arguments ) )
	if prepared.has( &"error" ):
		if on_done.is_valid():
			on_done.call( result_from_text( str( prepared[&"error"] ) ) )
		return
	if prepared.get( &"wait", false ) == true:
		_in_flight = true
		_paint_on_done = on_done
		_paint_path = str( prepared[&"path"] )
		_paint_level = level
		_schedule_read()
		return
	if on_done.is_valid():
		on_done.call( result_from_text( _read_issues( str( prepared[&"path"] ), level ) ) )


func _execute_line( args:String, _context:Dictionary ) -> String:
	var arguments:Dictionary = arguments_from_line( args, "" )
	var resolved:Dictionary = _resolve_level( arguments )
	if resolved.has( &"error" ):
		return str( resolved[&"error"] )
	var prepared:Dictionary = _prepare( str( arguments[&"path"] ) )
	if prepared.has( &"error" ):
		return str( prepared[&"error"] )
	return _read_issues( str( prepared[&"path"] ), _narrow_int( resolved[&"level"] ) )


func _prepare( args:String ) -> Dictionary:
	var file_path:String = args.strip_edges()
	if file_path.is_empty():
		return { &"error": "ERROR: FBS_DIAGNOSE requires a path. Usage: " + get_usage() }
	if not file_path.begins_with( "res://" ) \
			and not file_path.begins_with( "user://" ):
		return { &"error": "ERROR: Path must be res:// or user:// (got '%s')" % file_path }
	if file_path.get_extension().to_lower() != "fbs":
		return { &"error": "ERROR: Expected .fbs: " + file_path }
	if not FileAccess.file_exists( file_path ):
		return { &"error": "ERROR: Schema not found: " + file_path }

	var closed:String = _close_tab( file_path )
	if not closed.is_empty():
		return { &"error": closed }

	var dock:FileSystemDock = EditorInterface.get_file_system_dock()
	if not is_instance_valid( dock ):
		return { &"error": "ERROR: FileSystem dock is not available" }
	dock.navigate_to_path( file_path )
	if not _activate_path( dock, file_path ):
		return { &"error": "ERROR: FileSystem dock has no row for " + file_path }
	EditorInterface.set_main_screen_editor( "Script" )

	var tab:Dictionary = _current_tab( file_path )
	if tab.has( &"error" ):
		return tab
	var text_edit:TextEdit = tab[&"text_edit"]
	var highlighter:SyntaxHighlighter = _schema_highlighter( text_edit )
	if highlighter == null:
		return { &"error": "ERROR: FlatBuffers schema highlighter is not available for " + file_path }
	text_edit.queue_redraw()
	return { &"path": file_path, &"wait": true }


## Close the script-editor tab so the next open builds a new highlighter.
## A missing tab is fine. close_file reloads an unsaved buffer from disk, then closes it.
func _close_tab( file_path:String ) -> String:
	var script_editor:ScriptEditor = EditorInterface.get_script_editor()
	if not is_instance_valid( script_editor ) or not script_editor.has_method( &"close_file" ):
		return "ERROR: No ScriptEditor.close_file"
	var err:Error = script_editor.close_file( file_path )
	if err == OK or err == ERR_FILE_NOT_FOUND:
		return ""
	return "ERROR: ScriptEditor.close_file failed (%s): %s" % [ error_string( err ), file_path ]


func _activate_path( dock:Node, file_path:String ) -> bool:
	var tree:Tree = _find_tree( dock )
	if is_instance_valid( tree ):
		var selected:TreeItem = tree.get_selected()
		if selected != null and str( selected.get_metadata( 0 ) ) == file_path:
			tree.item_activated.emit()
			return true

	var files:ItemList = _find_item_list( dock )
	if not is_instance_valid( files ):
		return false
	for idx:int in files.item_count:
		if str( files.get_item_metadata( idx ) ) == file_path:
			files.item_activated.emit( idx )
			return true
	return false


func _current_tab( file_path:String ) -> Dictionary:
	var script_editor:ScriptEditor = EditorInterface.get_script_editor()
	if not is_instance_valid( script_editor ):
		return { &"error": "ERROR: Script editor is not available" }
	var current:ScriptEditorBase = script_editor.get_current_editor()
	if not is_instance_valid( current ):
		return { &"error": "ERROR: Script editor did not open a tab for " + file_path }
	var base:Control = current.get_base_editor()
	if not base is TextEdit:
		return { &"error": "ERROR: Opened tab is not a text editor for " + file_path }
	var edited:String = _edited_path( current )
	if not edited.is_empty() and edited != file_path:
		return { &"error": "ERROR: Opened tab does not match " + file_path }
	if edited.is_empty():
		var text_edit:TextEdit = base as TextEdit
		var shown:String = text_edit.get_text().replace( "\r\n", "\n" ).strip_edges()
		var disk:String = FileAccess.get_file_as_string( file_path ).replace( "\r\n", "\n" ).strip_edges()
		if shown != disk:
			return { &"error": "ERROR: Opened tab does not match " + file_path }
	return { &"text_edit": base as TextEdit }


func _read_issues( file_path:String, level:int = -1 ) -> String:
	var tab:Dictionary = _current_tab( file_path )
	if tab.has( &"error" ):
		return str( tab[&"error"] )
	var text_edit:TextEdit = tab[&"text_edit"]
	var highlighter:SyntaxHighlighter = _schema_highlighter( text_edit )
	if highlighter == null:
		return "ERROR: FlatBuffers schema highlighter is not available for " + file_path
	var parser:Object = highlighter.get( "parser" )
	if parser == null or not parser.has_method( &"format_issues" ):
		return "ERROR: Schema highlighter has no issue list for " + file_path
	var log_text:String = ""
	if level >= 0:
		log_text = "\n".join( _reparse_at( highlighter, text_edit, parser, level ) )
	parser.call( &"prune_issues", text_edit.get_line_count() )
	var issue_text:String = str( parser.call( &"format_issues", level ) )
	var issue_count:int = _narrow_int( parser.call( &"issue_count" ) )
	var header:String = "OK: FBS_DIAGNOSE %s lines=%d issues=%d" % [
		file_path,
		text_edit.get_line_count(),
		issue_count,
	]
	if level >= 0:
		header += " level=%s" % _level_name( level )
	var body:String = issue_text
	if not log_text.is_empty():
		body = log_text if body.is_empty() else body + "\n" + log_text
	if body.is_empty():
		return header
	return header + "\n" + body


func _schedule_read() -> void:
	var err:int = RenderingServer.frame_post_draw.connect( _on_painted, CONNECT_ONE_SHOT )
	if err != OK:
		_finish_paint( "ERROR: FBS_DIAGNOSE could not wait for the editor to paint" )


func _on_painted() -> void:
	var path:String = _paint_path
	var level:int = _paint_level
	_finish_paint( _read_issues( path, level ) )


func _finish_paint( reply:String ) -> void:
	var done:Callable = _paint_on_done
	_paint_on_done = Callable()
	_paint_path = ""
	_paint_level = -1
	_in_flight = false
	if done.is_valid():
		done.call( result_from_text( reply ) )


## Reparse every line at [param level] and return the lines the logger emitted.
## The previous backend and ceiling are put back afterwards.
func _reparse_at(
		highlighter:SyntaxHighlighter,
		text_edit:TextEdit,
		parser:Object,
		level:int
) -> PackedStringArray:
	var capture:LogCapture = LogCapture.new()
	capture.forward = Log.backend
	var previous_level:int = Log._session().default_lvl
	var previous_backend:Object = Log.backend
	var previous_disabled:bool = Log.is_disabled()
	Log.set_backend( capture )
	Log._session().default_lvl = level
	if parser.has_method( &"clear_cache" ):
		parser.call( &"clear_cache" )
	for line_idx:int in text_edit.get_line_count():
		@warning_ignore("return_value_discarded")
		highlighter.call( &"_get_line_syntax_highlighting", line_idx )
	if is_instance_valid( previous_backend ):
		Log.set_backend( previous_backend )
	else:
		Log.clear_backend()
	Log._session().default_lvl = previous_level
	if previous_disabled:
		Log.disable()
	return capture.lines


func _narrow_int( value:Variant ) -> int:
	if value is int:
		var number:int = value
		return number
	return -1


func _resolve_level( arguments:Dictionary ) -> Dictionary:
	var text:String = _level_text( arguments )
	if text.is_empty():
		return { &"level": -1 }
	var level:int = _parse_level( text )
	if level < 0:
		return { &"error": "ERROR: Unknown log level '%s'. Usage: %s" % [text, get_usage()] }
	return { &"level": level }


func _level_text( arguments:Dictionary ) -> String:
	if arguments.has( &"level" ):
		return str( arguments[&"level"] ).strip_edges()
	if arguments.has( "level" ):
		return str( arguments["level"] ).strip_edges()
	return ""


func _looks_like_level( token:String ) -> bool:
	return _parse_level( token ) >= 0


func _parse_level( token:String ) -> int:
	match token.strip_edges().to_upper():
		"SILENT": return Log.Level.SILENT
		"CRITICAL": return Log.Level.CRITICAL
		"ERROR": return Log.Level.ERROR
		"WARNING": return Log.Level.WARNING
		"NOTICE": return Log.Level.NOTICE
		"INFO": return Log.Level.INFO
		"DEBUG": return Log.Level.DEBUG
		"TRACE": return Log.Level.TRACE
	if token.is_valid_int():
		return token.to_int()
	return -1


func _level_name( level:int ) -> String:
	var key:Variant = Log.Level.find_key( level )
	if key == null:
		return str( level )
	return str( key )


func _edited_path( editor:Node ) -> String:
	if not editor.has_method( &"get_edited_resource" ):
		return ""
	var res_v:Variant = editor.call( &"get_edited_resource" )
	if not res_v is Resource:
		return ""
	var res:Resource = res_v
	return res.resource_path


func _schema_highlighter( text_edit:TextEdit ) -> SyntaxHighlighter:
	var current:SyntaxHighlighter = text_edit.get_syntax_highlighter()
	if _is_schema_highlighter( current ):
		return current
	if FlatBuffersPlugin._prime == null or FlatBuffersPlugin._prime.highlighter == null:
		return null
	var created:EditorSyntaxHighlighter = FlatBuffersPlugin._prime.highlighter._create()
	if not _is_schema_highlighter( created ):
		return null
	text_edit.set_syntax_highlighter( created )
	return created


func _is_schema_highlighter( highlighter:SyntaxHighlighter ) -> bool:
	if highlighter == null:
		return false
	var script:Script = highlighter.get_script()
	if script == null:
		return false
	return script.resource_path.get_file() == "schema_highlighter.gd"


func _find_tree( node:Node ) -> Tree:
	if node is Tree:
		return node
	for child:Node in node.get_children():
		var found:Tree = _find_tree( child )
		if is_instance_valid( found ):
			return found
	return null


func _find_item_list( node:Node ) -> ItemList:
	if node is ItemList:
		return node
	for child:Node in node.get_children():
		var found:ItemList = _find_item_list( child )
		if is_instance_valid( found ):
			return found
	return null


## Records logger lines for one diagnose reparse, and forwards them when a
## backend was already bound.
class LogCapture extends RefCounted:
	var lines:PackedStringArray = PackedStringArray()
	var forward:Object = null


	func lvl( p_lvl:int, content:Variant, object:Object, stack:Array ) -> void:
		_keep( content )
		if _can_forward( &"lvl" ):
			forward.call( &"lvl", p_lvl, content, object, stack )


	func rich( p_lvl:int, content:Variant, object:Object, stack:Array ) -> void:
		_keep( content )
		if _can_forward( &"rich" ):
			forward.call( &"rich", p_lvl, content, object, stack )


	func trace( args:Dictionary, object:Object, stack:Array ) -> void:
		_keep( args )
		if _can_forward( &"trace" ):
			forward.call( &"trace", args, object, stack )


	func _can_forward( method:StringName ) -> bool:
		return is_instance_valid( forward ) and forward.has_method( method )


	func _keep( content:Variant ) -> void:
		@warning_ignore("return_value_discarded")
		lines.append( str( content ) )
