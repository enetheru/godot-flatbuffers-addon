@tool
class_name FlatBuffersGeneratorOpts
extends Resource

##                                                       [br]
## │  __ _      _         ___       _   _                [br]
## │ / _| |__ _| |_ __   / _ \ _ __| |_(_)___ _ _  ___   [br]
## │|  _| / _` |  _/ _| | (_) | '_ \  _| / _ \ ' \(_-<   [br]
## │|_| |_\__,_|\__\__|  \___/| .__/\__|_\___/_||_/__/   [br]
## ╰──────────────────────────|_|─────────────────────── [br]
## A helper [Resource] to define the generation options used when running the
## flatc generator on the schema definitions.
##
## The Godot-FlatBuffers addon uses the flatc executable, from the FlatBuffers
## project, to transform a schema file(.fbs) into GDScript class to facilitae
## the serialisation and deserialsation of Godot native types into the format
## described by the FlatBuffers schema definition.[br]
## [br]
## This resource is used, by the Godot-Flatbuffers addon, to set the command line
## flags when calling flatc to generate the GDScript code.[br]
## [br]
## [color=goldenrod]TODO[/color] - Save to project settings.

@export
var name:String = 'UnNamed'

## The path to the flatc executable.
@export_custom( PROPERTY_HINT_GLOBAL_FILE, "*.exe", PROPERTY_USAGE_DEFAULT)
var flatc_exe:String

func                        __Basic_Opts_____________              ()->void:pass
#region Basic Opts
#MARK: Basic Opts
##                                            [br]
## │ ___          _       ___       _         [br]
## │| _ ) __ _ __(_)__   / _ \ _ __| |_ ___   [br]
## │| _ \/ _` (_-< / _| | (_) | '_ \  _(_-<   [br]
## │|___/\__,_/__/_\__|  \___/| .__/\__/__/   [br]
## ╰──────────────────────────|_|──────────── [br]

@export_category("Basic Options")

## -o PATH, Prefix PATH to all generated files
@export_custom( PROPERTY_HINT_GLOBAL_DIR, "")
var output_path:String


@export
## -I PATH, Search for includes in the specified path[br]
## It is unfortunate that the syntax highlighter cannot know the path of the
## currently edited file, so all paths must be absolute, or directly relative
## to an include path.
var include_paths:PackedStringArray

@export
var add_godot_fbs_to_include_paths:bool = true

@export
## Inhibit all warnings messages
var no_warnings:bool


@export
 ##Treat all warnings as errors
var warnings_as_errors:bool

#endregion Basic

func                        __Input_Schema_Opts______              ()->void:pass
#region Input Schema Opts
#MARK: Input Schema Opts
##                                                                               [br]
## │ ___                _     ___     _                      ___       _         [br]
## │|_ _|_ _  _ __ _  _| |_  / __| __| |_  ___ _ __  __ _   / _ \ _ __| |_ ___   [br]
## │ | || ' \| '_ \ || |  _| \__ \/ _| ' \/ -_) '  \/ _` | | (_) | '_ \  _(_-<   [br]
## │|___|_||_| .__/\_,_|\__| |___/\__|_||_\___|_|_|_\__,_|  \___/| .__/\__/__/   [br]
## ╰─────────|_|─────────────────────────────────────────────────|_|──────────── [br]

@export_category("Input Schema Options")
### Schema's( fbs, bfbs, JSON, proto)
#|   󱏘   | --require-explicit-ids  | When parsing schemas, require explicit ids (id: x)                                   |
#|       | --conform FILE          | Specify a schema the following schemas should be a evolution of. Gives errors if not |
#|       | --conform-includes PATH | Include path for the schema given with --conform PATH                                |

### JSON
#| --allow-non-utf8 | Pass non-UTF-8 input through parser and emit nonstandard \\x escapes in JSON. (Default is to raisparse error on non-UTF-8 input. |
#| --strict-json    | Strict JSON: field names must be / will be quoted, ntrailing commas in tables/vectors                                            |

### .proto
#| --proto                         | Input is a .proto, translate to .fb                                                                                                                                                                                                                                                       |
#| --proto-id-gap                  | Action that should be taken when a gap between protobu ids found. Supported values: * 'nop' - do not car about gap * 'warn' - A warning message will be show about the gap in protobuf ids(default) * 'error' - A  error message will be shown and the fbs generation wil  be interrupted |
#| --proto-namespace-suffix SUFFIX | Add this namespace to any flatbuffers generated fro protobufs                                                                                                                                                                                                                             |
#| --keep-proto-id                 | Keep protobuf field ids in generated fbs file                                                                                                                                                                                                                                             |
#| --oneof-union                   | Translate .proto oneofs to flatbuffer unions                                                                                                                                                                                                                                              |

#endregion Schema Opts

func                        __Output_File_Opts_______              ()->void:pass
#region Output File Opts
#MARK: Output File Opts
##                                                                     [br]
## │  ___       _             _     ___ _ _        ___       _         [br]
## │ / _ \ _  _| |_ _ __ _  _| |_  | __(_) |___   / _ \ _ __| |_ ___   [br]
## │| (_) | || |  _| '_ \ || |  _| | _|| | / -_) | (_) | '_ \  _(_-<   [br]
## │ \___/ \_,_|\__| .__/\_,_|\__| |_| |_|_\___|  \___/| .__/\__/__/   [br]
## ╰───────────────|_|─────────────────────────────────|_|──────────── [br]

@export_category("Output File Options")

@export
## (--filename-ext EXT) The extension appended to the generated file names Default is language-specific (e.g., '.h' for C++)
var filename_ext: String

@export
## (--filename-suffix SUFFIX) The suffix appended to the generated file name  (Default is '_generated')
var filename_suffix: String

#endregion Output File Opts

func                        __Code_Generation_Opts___              ()->void:pass
#region Code Generation Opts
#MARK: Code Generation Opts
##                                                                                         [br]
## │  ___         _        ___                       _   _             ___       _         [br]
## │ / __|___  __| |___   / __|___ _ _  ___ _ _ __ _| |_(_)___ _ _    / _ \ _ __| |_ ___   [br]
## │| (__/ _ \/ _` / -_) | (_ / -_) ' \/ -_) '_/ _` |  _| / _ \ ' \  | (_) | '_ \  _(_-<   [br]
## │ \___\___/\__,_\___|  \___\___|_||_\___|_| \__,_|\__|_\___/_||_|  \___/| .__/\__/__/   [br]
## ╰───────────────────────────────────────────────────────────────────────|_|──────────── [br]

@export_category("Code Generation Options")

@export_custom(PROPERTY_HINT_ENUM, "gdscript, csharp, cpp, json, bfbs")
var lang:String = 'gdscript'

@export
## (--root-type T) Select or override the default root_type
var root_type: String

#|       | --reflect-names               | Add minimal type/name reflection                                                                                                                                                                                     |
#|       | --reflect-types               | Add minimal type reflection to code generation                                                                                                                                                                       |

@export
## (--gen-all) Generate not just code for the current schema files but for all
## files it includes as well. If the language uses a single file for output
## (by default the case for C++ and JS), all code will end up in this one file
var gen_all:bool = false

#|   󱏘   | --gen-includes                | (deprecated), this is the default behavior. If the original behavior is required (no include statements use --no-includes                                                                                            |
#|   󱏘   | --gen-mutable                 | Generate accessors that can mutate buffers in-place                                                                                                                                                                  |
#|   󱏘   | --gen-onefile                 | Generate a single output file for C#, Go, Java, Kotli and Python. Implies --no-include                                                                                                                               |
#|   󱏘   | --include-prefix PATH         | Prefix this PATH to any generated include statements                                                                                                                                                                 |
#|   󱏘   | --keep-prefix                 | Keep original prefix of schema include statement                                                                                                                                                                     |
#|       | --gen-json-emit               | Generates encoding code which emits Flatbuffers int JSON                                                                                                                                                             |
#|   󰜺   | --no-emit-min-max-enum-values | Disable generation of MIN and MAX enumerated values for scoped enums and prefixed enums                                                                                                                              |
#|        | --natural-utf8                | Output strings with UTF-8 as human-readable strings. By default, UTF-8 characters are printed as \\uXXX escapes                                                                                                      |


#endregion Code Generation Opts

func                        __Object_API_____________              ()->void:pass
#region Object API
#MARK: Object API
##                                               [br]
## │  ___  _     _        _       _   ___ ___    [br]
## │ / _ \| |__ (_)___ __| |_    /_\ | _ \_ _|   [br]
## │| (_) | '_ \| / -_) _|  _|  / _ \|  _/| |    [br]
## │ \___/|_.__// \___\__|\__| /_/ \_\_| |___|   [br]
## ╰──────────|__/────────────────────────────── [br]
@export_category("Generate Object API")

@export
## Generate an additional object-based API
var gen_object_api:bool = false

#|   󱏘   | --object-prefix PREFIX | Customize class prefix for C++ object-based API                                                       |
#|   󱏘   | --object-suffix SUFFIX | Customize class suffix for C++ object-based API  Default Value is \"T\"                               |
#|   󱏘   | --gen-compare          | Generate operator == for object-based API types                                                       |
#|       | --force-empty          | When serializing from object API representation, force  strings and vectors to empty rather than null |


#endregion Object API

func                        __Godot_RPC______________              ()->void:pass
#region Godot RPC
#MARK: Godot RPC
## │  ___         _     _     ___ ___  ___    [br]
## │ / __|___  __| |___| |_  | _ \ _ \/ __|   [br]
## │| (_ / _ \/ _` / _ \  _| |   /  _/ (__    [br]
## │ \___\___/\__,_\___/\__| |_|_\_|  \___|   [br]
## ╰───────────────────────────────────────── [br]
## [br]
## This is kind of a pun, because the standard in flatbuffers is Google's GRPC
## I mean there is the possibility to incorporate GRPC into the extension and
## bind functions to it. But for now I will stick with godot's built in RPC's
@export_category("Godot RPC Generation")
#|       | --grpc                        | Generate GRPC interfaces for the specified languages                            |
#|       | --grpc-additional-header      | Additional headers to prepend to the generated files                            |
#|       | --grpc-callback-api           | Generate gRPC code using the callback (reactor) AP instead of legacy sync/async |
#|       | --grpc-filename-suffix SUFFIX | The suffix for the generated file names (Default i  '.fb')                      |
#|       | --grpc-python-typed-handlers  | The handlers will use the generated classes rather tha  raw bytes               |
#|       | --grpc-search-path PATH       | Prefix to any gRPC includes                                                     |
#|   󰜺   | --grpc-use-system-headers     | Use <> for headers included from the generated code                             |


#endregion Godot RPC

func                        __GDScript_Opts__________              ()->void:pass
#region GDScript Opts
#MARK: GDScript Opts
##                                                           [br]
## │  ___ ___  ___         _      _      ___       _         [br]
## │ / __|   \/ __| __ _ _(_)_ __| |_   / _ \ _ __| |_ ___   [br]
## │| (_ | |) \__ \/ _| '_| | '_ \  _| | (_) | '_ \  _(_-<   [br]
## │ \___|___/|___/\__|_| |_| .__/\__|  \___/| .__/\__/__/   [br]
## ╰────────────────────────|_|──────────────|_|──────────── [br]
## [br]
## This is going to be a brainstorm for the moment of the kinds of things that
## may be doable.
@export_category("GDScript Generation Options")
# -

@export
## Adds some debugging print functions
var gdscript_debug:bool = false

#@export
#var flatc_generate_pack_unpack:bool = false

#endregion GDScript Opts

#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

# TODO validate the properties as they are set.
#func _validate_property(property: Dictionary) -> void:
	#pass

func get_opts() -> PackedStringArray:
	var args:Array = []
	## --- Basic Options ----------

	if not output_path.is_empty():
		args.append_array(['-o', output_path])

	for path:String in get_include_paths():
		# TODO transform user:// and res:// to system paths
		args.append_array(['-I', path.replace('res://', './')])

	# -I <path>                Search for includes in the specified path.
	#var dir_access := DirAccess.open("res://")
	#for ipath in include_paths:
		#if not DirAccess.dir_exists_absolute(ipath):
			#push_warning("invalid include path: '%s'" % ipath)
			#continue
		#args.append_array(["-I", ipath.replace('res://', './')])

	## --- Output File Options ----------
	if not filename_ext.is_empty():
		args.append_array(["--filename-ext", filename_ext])

	if not filename_suffix.is_empty():
		args.append_array(["--filename-suffix", filename_suffix])

	## --- Code Generation Options ----------
	
	args.append('--%s' % lang)

	## Which Language to generate
	if not root_type.is_empty():
		args.append_array(["--root-type", root_type])

	if gen_all:
		args.append("--gen-all")

	## --- Object API Options ----------

	## Generate object API
	if gen_object_api:
		args.append("--gen-object-api")

	## --- GDScript Options ----------

	## Generate Additional Debug Output
	if gdscript_debug:
		args.append("--gdscript-debug")

	return args


func get_include_paths() -> Array:
	var paths:Array = include_paths.duplicate()
	
	## always include the project root
	paths.append("res://")

	## Include the extension res folder for godot.fbs inclusion
	if add_godot_fbs_to_include_paths:
		var plugin_script:Resource = FlatBuffersPlugin
		var plugin_path:String = plugin_script.resource_path.get_base_dir()
		paths.append(plugin_path.path_join('res'))

	return paths
