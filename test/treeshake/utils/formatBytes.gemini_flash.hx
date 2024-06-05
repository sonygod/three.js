class FormatBytes {

	public static function formatBytes(bytes:Float, decimals:Int = 1):String {
		if (bytes == 0) return "0 B";

		var k = 1000;
		var dm = decimals < 0 ? 0 : decimals;
		var sizes:Array<String> = ["B", "kB", "MB", "GB"];

		var i = Math.floor(Math.log(bytes) / Math.log(k));

		return Std.parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + " " + sizes[i];
	}
}


Here's a breakdown of the changes:

* **Class Structure:** Haxe uses classes for organizing code. We create a class named `FormatBytes` to hold the `formatBytes` function.
* **`export` Keyword:** Haxe doesn't use `export` in the same way as JavaScript for module exports. Instead, you would use a tool like Haxelib to create a library and package your code.
* **`Float` and `Int` Types:** Haxe has explicit type declarations. We use `Float` for `bytes` and `Int` for `decimals`.
* **`Std.parseFloat`:** Haxe uses the `Std` class for standard library functions. We use `Std.parseFloat` to convert the string result of `toFixed` back to a number.
* **`Array<String>`:**  We use an array of strings to store the size units.
* **No Semicolons:** Haxe doesn't require semicolons at the end of statements.

**Usage:**

You would call the function like this:


var formattedSize = FormatBytes.formatBytes(1234567, 2); // Output: "1.23 MB"