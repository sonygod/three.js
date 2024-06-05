// This easy console wrapper introduces the logging level to console for
// preventing console outputs caused when we purposely test the code path
// including console outputs.
//
// Example: Prevent the console warnings caused by Color.setStyle().
//   const c = new Color();
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
	public static level : CONSOLE_LEVEL = CONSOLE_LEVEL.DEFAULT;

	static _error : Dynamic = js.Browser.window.console.error;
	static _warn : Dynamic = js.Browser.window.console.warn;
	static _log : Dynamic = js.Browser.window.console.log;
	static _info : Dynamic = js.Browser.window.console.info;
	static _debug : Dynamic = js.Browser.window.console.debug;

	static error(...args : Dynamic[]) {
		if (ConsoleWrapper.level >= CONSOLE_LEVEL.ERROR) {
			ConsoleWrapper._error.apply(js.Browser.window.console, args);
		}
	}

	static warn(...args : Dynamic[]) {
		if (ConsoleWrapper.level >= CONSOLE_LEVEL.WARN) {
			ConsoleWrapper._warn.apply(js.Browser.window.console, args);
		}
	}

	static log(...args : Dynamic[]) {
		if (ConsoleWrapper.level >= CONSOLE_LEVEL.LOG) {
			ConsoleWrapper._log.apply(js.Browser.window.console, args);
		}
	}

	static info(...args : Dynamic[]) {
		if (ConsoleWrapper.level >= CONSOLE_LEVEL.INFO) {
			ConsoleWrapper._info.apply(js.Browser.window.console, args);
		}
	}

	static debug(...args : Dynamic[]) {
		if (ConsoleWrapper.level >= CONSOLE_LEVEL.DEBUG) {
			ConsoleWrapper._debug.apply(js.Browser.window.console, args);
		}
	}
}

// Export the class
export class Console {
    static level : CONSOLE_LEVEL = ConsoleWrapper.level;
    static error(...args : Dynamic[]) {
        ConsoleWrapper.error(...args);
    }
    static warn(...args : Dynamic[]) {
        ConsoleWrapper.warn(...args);
    }
    static log(...args : Dynamic[]) {
        ConsoleWrapper.log(...args);
    }
    static info(...args : Dynamic[]) {
        ConsoleWrapper.info(...args);
    }
    static debug(...args : Dynamic[]) {
        ConsoleWrapper.debug(...args);
    }
}


**Explanation:**

1. **Enum for Console Levels:** The `CONSOLE_LEVEL` enum is defined to represent different logging levels (OFF, ERROR, WARN, LOG, INFO, DEBUG, ALL, DEFAULT). This is the same as the JavaScript version.

2. **ConsoleWrapper Class:** A `ConsoleWrapper` class is created to hold the modified console methods and the `level` property. The class is static, which means you don't need to instantiate it.

3. **Saving Original Console Methods:**  We store the original `console.error`, `console.warn`, etc. methods in the `ConsoleWrapper` class using `js.Browser.window.console.error`, `js.Browser.window.console.warn`, etc. This is how we access the original console methods in Haxe.

4. **Wrapping Console Methods:** The `ConsoleWrapper` class defines static methods for `error`, `warn`, `log`, `info`, and `debug`. These methods check the `ConsoleWrapper.level` and call the original console methods only if the current level is high enough.

5. **Exporting the Console Class:**  Finally, a `Console` class is created to provide a more convenient interface for using the console wrapper. This class has the same methods as the `ConsoleWrapper` class and sets its `level` property to the `level` property of the `ConsoleWrapper` class.

**How to Use:**


import Console;

class Main {
	static function main() {
		// Set the console level to ERROR
		Console.level = Console.ERROR;

		// This log message won't be printed
		Console.log("This message will be ignored");

		// This error message will be printed
		Console.error("This message will be printed");
	}
}