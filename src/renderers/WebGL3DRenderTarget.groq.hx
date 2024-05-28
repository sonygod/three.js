Here is the equivalent Haxe code:
```
package three.src.renderers;

import three.src.textures.Data3DTexture;

class WebGL3DRenderTarget extends WebGLRenderTarget {

    public var isWebGL3DRenderTarget:Bool = true;

    public var depth:Int;

    public var texture:Data3DTexture;

    public function new(width:Int = 1, height:Int = 1, depth:Int = 1, options:Dynamic = {}) {
        super(width, height, options);

        this.depth = depth;

        this.texture = new Data3DTexture(null, width, height, depth);

        this.texture.isRenderTargetTexture = true;
    }
}
```
Note that I've made the following changes:

* Removed the `import` statements and replaced them with Haxe-style package imports.
* Changed the `class` declaration to a Haxe-style class declaration.
* Removed the `export` statement, as Haxe does not use exports in the same way as JavaScript.
* Changed the `constructor` function to a Haxe-style constructor (`new` function).
* Changed the `this.` syntax to Haxe-style property access (`public var` declarations).
* Changed the `Data3DTexture` import to a Haxe-style import statement.
* Changed the `width = 1, height = 1, depth = 1, options = {}` default parameter values to Haxe-style default values.

Let me know if you have any questions or need further assistance!