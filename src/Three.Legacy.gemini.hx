import three.renderers.WebGLRenderTarget;

class WebGLMultipleRenderTargets extends WebGLRenderTarget {
	public function new(width:Float = 1, height:Float = 1, count:Int = 1, options:Dynamic = {}) {
		#if three_major < 172
		Sys.warning("THREE.WebGLMultipleRenderTargets has been deprecated and will be removed in r172. Use THREE.WebGLRenderTarget and set the \"count\" parameter to enable MRT.");
		#end
		super(width, height, {
			...options,
			count: count
		});
		this.isWebGLMultipleRenderTargets = true;
	}

	public var texture(get, never):Array<Dynamic>;
	inline function get_texture():Array<Dynamic> {
		return this.textures;
	}
}


**Explanation:**

1. **Import:** We import the `WebGLRenderTarget` class from the `three.renderers` package.
2. **Class Definition:** We define the `WebGLMultipleRenderTargets` class extending `WebGLRenderTarget`.
3. **Constructor:**
   - We add a deprecation warning for versions below r172 using the `#if` directive.
   - The constructor calls the superclass constructor with the provided `width`, `height`, `count`, and `options`.
4. **`isWebGLMultipleRenderTargets`:** The class property is set to `true` for identification.
5. **`texture` getter:** We define a getter for the `texture` property that returns the `textures` array.

**Key Points:**

- The code uses the `Dynamic` type to represent any JavaScript object, as Haxe doesn't have a direct equivalent for JavaScript objects.
- The `...` operator is used to spread the `options` object with the `count` parameter for passing it to the `super` constructor.
- The deprecation warning is only shown for versions below r172 using the `#if` directive.

**Using the Class:**


import three.renderers.WebGLMultipleRenderTargets;

var mrt = new WebGLMultipleRenderTargets(512, 512, 4); // Create MRT with 4 textures
var textures:Array<Dynamic> = mrt.texture; // Get the textures array