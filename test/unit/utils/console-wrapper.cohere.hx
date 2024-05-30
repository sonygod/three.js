package js;

@:expose
class Console {
    static var level:Int = 6;

    static public function error(msg:Dynamic, ?info:Dynamic) {
        if (level >= 1) {
            _error(msg, info);
        }
    }

    static public function warn(msg:Dynamic, ?info:Dynamic) {
        if (level >= 2) {
            _warn(msg, info);
        }
    }

    static public function log(msg:Dynamic, ?info:Dynamic) {
        if (level >= 3) {
            _log(msg, info);
        }
    }

    static public function info(msg:Dynamic, ?info:Dynamic) {
        if (level >= 4) {
            _info(msg, info);
        }
    }

    static public function debug(msg:Dynamic, ?info:Dynamic) {
        if (level >= 5) {
            _debug(msg, info);
        }
    }

    static private function _error(msg:Dynamic, ?info:Dynamic) {
        #if js
        js.Browser.console.error(msg, info);
        #end
    }

    static private function _warn(msg:Dynamic, ?info:Dynamic) {
        #if js
        js.Browser.console.warn(msg, info);
        #end
    }

    static private function _log(msg:Dynamic, ?info:Dynamic) {
        #if js
        js.Browser.console.log(msg, info);
        #end
    }

    static private function _info(msg:Dynamic, ?info:Dynamic) {
        #if js
        js.Browser.console.info(msg, info);
        #end
    }

    static private function _debug(msg:Dynamic, ?info:Dynamic) {
        #if js
        js.Browser.console.debug(msg, info);
        #end
    }
}

enum ConsoleLevel {
    OFF,
    ERROR,
    WARN,
    LOG,
    INFO,
    DEBUG,
    ALL,
    DEFAULT
}

class ConsoleWrapper {
    static public function setLevel(lvl:ConsoleLevel) {
        Console.level = lvl.index;
    }
}

class Main {
    static public function main() {
        ConsoleWrapper.setLevel(ConsoleLevel.DEFAULT);

        Console.log("This is a log message");
        Console.warn("This is a warning message");
        Console.error("This is an error message");

        ConsoleWrapper.setLevel(ConsoleLevel.OFF);

        Console.log("This log message won't be displayed");
        Console.warn("This warning message won't be displayed");
        Console.error("This error message won't be displayed");
    }
}