Here is the equivalent Haxe code:
```
package three.shader;

class ClippingPlanesVertex {
    public function new() {}

    public static var shader:String = '
#if NUM_CLIPPING_PLANES > 0

	vClipPosition = - mvPosition.xyz;

#endif
';
}
```
Note that in Haxe, we don't have a direct equivalent to JavaScript's `export default`, so I've wrapped the shader code in a `ClippingPlanesVertex` class, and made the shader code a static variable `shader`.

Also, since Haxe is a statically-typed language, we need to specify the type of the `shader` variable, which in this case is a `String`.

Let me know if you have any further questions!