// ConsoleWrapper.hx

// Define the console levels as an enumeration
enum ConsoleLevel {
    OFF;
    ERROR;
    WARN;
    LOG;
    INFO;
    DEBUG;
    ALL;
    DEFAULT;
}

class ConsoleWrapper {
    public static var level:Int = ConsoleLevel.DEFAULT;

    // Save the original console methods
    static var _error:Dynamic = js.Browser.console.error;
    static var _warn:Dynamic = js.Browser.console.warn;
    static var _log:Dynamic = js.Browser.console.log;
    static var _info:Dynamic = js.Browser.console.info;
    static var _debug:Dynamic = js.Browser.console.debug;

    // Wrap the console methods
    static function error(?args:Array<Dynamic>) {
        if (level >= ConsoleLevel.ERROR) _error.apply(js.Browser.console, args);
    }

    static function warn(?args:Array<Dynamic>) {
        if (level >= ConsoleLevel.WARN) _warn.apply(js.Browser.console, args);
    }

    static function log(?args:Array<Dynamic>) {
        if (level >= ConsoleLevel.LOG) _log.apply(js.Browser.console, args);
    }

    static function info(?args:Array<Dynamic>) {
        if (level >= ConsoleLevel.INFO) _info.apply(js.Browser.console, args);
    }

    static function debug(?args:Array<Dynamic>) {
        if (level >= ConsoleLevel.DEBUG) _debug.apply(js.Browser.console, args);
    }
}