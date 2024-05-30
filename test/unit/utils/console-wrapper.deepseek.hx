// This easy console wrapper introduces the logging level to console for
// preventing console outputs caused when we purposely test the code path
// including console outputs.
//
// Example: Prevent the console warnings caused by Color.setStyle().
//   var c = new Color();
//   console.level = CONSOLE_LEVEL.ERROR;
//   c.setStyle( 'rgba(255,0,0,0.5)' );
//   console.level = CONSOLE_LEVEL.DEFAULT;
//
// See https://github.com/mrdoob/three.js/issues/20760#issuecomment-735190998

enum CONSOLE_LEVEL {
	OFF = 0;
	ERROR = 1;
	WARN = 2;
	LOG = 3;
	INFO = 4;
	DEBUG = 5;
	ALL = 6;
	DEFAULT = 6;
}

class ConsoleWrapper {

	var _error:Dynamic;
	var _warn:Dynamic;
	var _log:Dynamic;
	var _info:Dynamic;
	var _debug:Dynamic;

	public function new() {
		_error = js.Browser.console.error;
		_warn = js.Browser.console.warn;
		_log = js.Browser.console.log;
		_info = js.Browser.console.info;
		_debug = js.Browser.console.debug;
	}

	public function error(level:CONSOLE_LEVEL, message:String) {
		if (level >= CONSOLE_LEVEL.ERROR) _error(message);
	}

	public function warn(level:CONSOLE_LEVEL, message:String) {
		if (level >= CONSOLE_LEVEL.WARN) _warn(message);
	}

	public function log(level:CONSOLE_LEVEL, message:String) {
		if (level >= CONSOLE_LEVEL.LOG) _log(message);
	}

	public function info(level:CONSOLE_LEVEL, message:String) {
		if (level >= CONSOLE_LEVEL.INFO) _info(message);
	}

	public function debug(level:CONSOLE_LEVEL, message:String) {
		if (level >= CONSOLE_LEVEL.DEBUG) _debug(message);
	}
}

var console = new ConsoleWrapper();