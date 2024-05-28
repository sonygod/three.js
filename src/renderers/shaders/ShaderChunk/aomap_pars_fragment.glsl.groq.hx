Here is the equivalent Haxe code for the given JavaScript code:
```
package three.shader;

class AoMapParsFragment {
    public static var shader:String = "
#ifdef USE_AOMAP

    uniform sampler2D aoMap;
    uniform float aoMapIntensity;

#endif
    ";
}
```
Note that in Haxe, we don't need to use the `export default` syntax, and instead, we can define a `class` with a `shader` variable that contains the GLSL code as a string.

Also, I added a `package` declaration to match the file path you provided, and a `class` name that follows the Haxe convention.

Please note that this is a Haxe 4 compatible code. If you are using Haxe 3, you might need to adjust the syntax slightly.