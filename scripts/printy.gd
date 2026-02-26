
# │ ___    _ _ _           _
# │| __|__| (_) |_ ___ _ _| |   ___  __ _
# │| _|/ _` | |  _/ _ \ '_| |__/ _ \/ _` |
# │|___\__,_|_|\__\___/_| |____\___/\__, |
# ╰─────────────────────────────────|___/──
enum LogLevel {
	SILENT = 0,
	CRITICAL = 1,
	ERROR = 2,
	WARNING = 3,
	NOTICE = 4,
	DEBUG = 5,
	TRACE = 6,
}

static var _opts:FlatBuffersOpts:
	get(): return FlatBuffersPlugin._prime.opts
	set(v):pass


static var _verbosity:int :
	get(): return _opts.editorlog_verbosity
	set(v):pass


static func ptrace() -> void:
	if _verbosity < LogLevel.TRACE: return
	var colour:String = _opts .get_colour(LogLevel.TRACE).to_html()
	var call_site:Dictionary = get_stack()[-1]
	var line:String = "[url='{source}:{line}'][color=57b3ff]{function}[/color][/url]".format(call_site)
	print_rich( "[color=%s]%s[/color]" % [colour, line] )


static func plog( level:LogLevel, message:String ) -> void:
	if _verbosity < level: return
	var colour:String = _opts.get_colour(level).to_html()
	var padding:String = "".lpad(get_stack().size()-1, '\t') if level == LogLevel.TRACE else ""
	print_rich( padding + "[color=%s]%s[/color]" % [colour, message] )


static func plog_check( level:LogLevel, message:String ) -> bool:
	if _verbosity < level: return false
	plog(level, message)
	return true


static func lvl( level:LogLevel ) -> bool:
	return _verbosity >= level
