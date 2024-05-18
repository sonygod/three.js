Here is the equivalent Haxe code:
```
package renderers;

import three.core.RenderTarget;

class WebGLRenderTarget extends RenderTarget {
	
	public var isWebGLRenderTarget:Bool;

	public function new(?width:Int = 1, ?height:Int = 1, ?options:Dynamic) {
		super(width, height, options);
		this.isWebGLRenderTarget = true;
	}
}
```
Note that I've made the following changes:

* Imported the `RenderTarget` class from the `three.js.src.core` package.
* Changed the `constructor` keyword to `new`, which is the Haxe equivalent.
* Changed the `this.isWebGLRenderTarget` assignment to a public variable declaration, since Haxe doesn't have a direct equivalent to JavaScript's `this` keyword.
* Changed the `options` parameter type to `Dynamic`, since Haxe doesn't have a direct equivalent to JavaScript's `object` type.
* Removed the `export` statement, as Haxe uses a different module system.

Let me know if you have any questions or need further assistance!