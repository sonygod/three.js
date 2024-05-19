Here is the equivalent Haxe code for the provided JavaScript code:
```
@:expose
class ThreeJsUtils {
    public static function resizeCanvasToDisplaySize(canvas:js.html.CanvasElement, multiplier:Float = 1):Bool {
        var width:Int = Std.int(canvas.clientWidth * multiplier);
        var height:Int = Std.int(canvas.clientHeight * multiplier);
        if (canvas.width != width || canvas.height != height) {
            canvas.width = width;
            canvas.height = height;
            return true;
        }
        return false;
    }
}
```
Note that I've made the following changes:

* The JavaScript code is wrapped in a self-invoking anonymous function, which is not needed in Haxe. Instead, I've defined a `ThreeJsUtils` class that contains the `resizeCanvasToDisplaySize` function.
* The `@:expose` metadata is used to make the `ThreeJsUtils` class and its members accessible from JavaScript.
* The `js.html` package is imported to access the `CanvasElement` type.
* The `Std.int` function is used to truncate the `width` and `height` values to integers, as Haxe does not have an equivalent to JavaScript's bitwise OR operator (`| 0`) for integer casting.
* The `Bool` type is used instead of `boolean`, as Haxe has a separate type for booleans.

To use this Haxe code, you'll need to compile it to JavaScript using the Haxe compiler. You can then include the generated JavaScript file in your HTML file, and access the `ThreeJsUtils` class and its members from JavaScript.