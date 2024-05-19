package three.test.unit.utils;

class ConsoleWrapper {
    public static var CONSOLE_LEVEL = {
        OFF: 0,
        ERROR: 1,
        WARN: 2,
        LOG: 3,
        INFO: 4,
        DEBUG: 5,
        ALL: 6,
        DEFAULT: 6
    };

    public static var level:Int = CONSOLE_LEVEL.DEFAULT;

    private static var _error:Dynamic;
    private static var _warn:Dynamic;
    private static var _log:Dynamic;
    private static var _info:Dynamic;
    private static var _debug:Dynamic;

    static function init() {
        _error = untyped console.error;
        _warn = untyped console.warn;
        _log = untyped console.log;
        _info = untyped console.info;
        _debug = untyped console.debug;

        untyped console.error = error;
        untyped console.warn = warn;
        untyped console.log = log;
        untyped console.info = info;
        untyped console.debug = debug;
    }

    private static function error(arguments:Array<Dynamic>) {
        if (level >= CONSOLE_LEVEL.ERROR) _error.apply(null, arguments);
    }

    private static function warn(arguments:Array<Dynamic>) {
        if (level >= CONSOLE_LEVEL.WARN) _warn.apply(null, arguments);
    }

    private static function log(arguments:Array<Dynamic>) {
        if (level >= CONSOLE_LEVEL.LOG) _log.apply(null, arguments);
    }

    private static function info(arguments:Array<Dynamic>) {
        if (level >= CONSOLE_LEVEL.INFO) _info.apply(null, arguments);
    }

    private static function debug(arguments:Array<Dynamic>) {
        if (level >= CONSOLE_LEVEL.DEBUG) _debug.apply(null, arguments);
    }
}