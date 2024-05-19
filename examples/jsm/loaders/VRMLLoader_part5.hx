Here is the equivalent Haxe code:
```
package three.js.examples.jsm.loaders;

class Face {
    public var a:Dynamic;
    public var b:Dynamic;
    public var c:Dynamic;
    public var normal:Vector3;

    public function new(a:Dynamic, b:Dynamic, c:Dynamic) {
        this.a = a;
        this.b = b;
        this.c = c;
        this.normal = new Vector3();
    }
}
```
Note that I've assumed `Vector3` is a class that is already defined elsewhere in your Haxe project, and that it has a no-argument constructor. If that's not the case, you may need to modify the code accordingly.

Also, I've used `Dynamic` as the type for `a`, `b`, and `c` since the original JavaScript code didn't specify any particular type for those variables. If you know the types of `a`, `b`, and `c`, you should replace `Dynamic` with the actual types.