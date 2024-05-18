Here is the equivalent Haxe code:
```
package three.materials;

import three.materials.ShaderMaterial;

class RawShaderMaterial extends ShaderMaterial {

	public var isRawShaderMaterial:Bool = true;

	public function new(parameters:Dynamic) {
		super(parameters);
		this.type = 'RawShaderMaterial';
	}

}
```
Note:

* In Haxe, we use `package` instead of `import` to define the namespace.
* We don't need to use `export` in Haxe, as the class is already defined in the package.
* In Haxe, we use `public var` to define a public variable, and `public function` to define a public constructor.
* In Haxe, we use `Bool` instead of `boolean` for boolean types.
* In Haxe, we use `Dynamic` as the type for the `parameters` argument, since we don't know the exact type of the parameter.
* We don't need to use `this.` to access the class properties, as it is implied in Haxe.

Let me know if you have any questions or need further assistance!