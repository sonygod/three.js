class ConsoleWrapper {
    public static var CONSOLE_LEVEL:Map<String, Int> = [
        "OFF" => 0,
        "ERROR" => 1,
        "WARN" => 2,
        "LOG" => 3,
        "INFO" => 4,
        "DEBUG" => 5,
        "ALL" => 6,
        "DEFAULT" => 6
    ];

    public static function new() {
        // Save the original methods
        var _error = js.Browser.console.error;
        var _warn = js.Browser.console.warn;
        var _log = js.Browser.console.log;
        var _info = js.Browser.console.info;
        var _debug = js.Browser.console.debug;

        // Wrap console methods
        js.Browser.console.error = function(...args) {
            if (js.Browser.console.level >= CONSOLE_LEVEL.get("ERROR")) _error(...args);
        };

        js.Browser.console.warn = function(...args) {
            if (js.Browser.console.level >= CONSOLE_LEVEL.get("WARN")) _warn(...args);
        };

        js.Browser.console.log = function(...args) {
            if (js.Browser.console.level >= CONSOLE_LEVEL.get("LOG")) _log(...args);
        };

        js.Browser.console.info = function(...args) {
            if (js.Browser.console.level >= CONSOLE_LEVEL.get("INFO")) _info(...args);
        };

        js.Browser.console.debug = function(...args) {
            if (js.Browser.console.level >= CONSOLE_LEVEL.get("DEBUG")) _debug(...args);
        };

        js.Browser.console.level = CONSOLE_LEVEL.get("DEFAULT");
    }
}