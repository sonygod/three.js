Here is the equivalent Haxe code:
```
package three.js.src.textures;

import three.js.src.constants.CubeReflectionMapping;
import three.js.src.textures.CompressedTexture;

class CompressedCubeTexture extends CompressedTexture {

	public function new(images:Array<Dynamic>, format:Dynamic, type:Dynamic) {

		super(undefined, images[0].width, images[0].height, format, type, CubeReflectionMapping);

		this.isCompressedCubeTexture = true;
		this.isCubeTexture = true;

		this.image = images;

	}

}
```
Note that I've made the following changes:

* `import` statements are replaced with `import` statements in Haxe syntax.
* The `class` keyword is used to define the `CompressedCubeTexture` class.
* The `constructor` function is replaced with a `new` function, which is the Haxe equivalent.
* The `super` call is used to call the parent class constructor.
* The `this` keyword is used to access the instance properties.
* The `isCompressedCubeTexture` and `isCubeTexture` properties are assigned using simple assignments.
* The `image` property is assigned the `images` array.
* The `export` statement is not needed in Haxe, as classes and variables are automatically exported.

Please note that I've assumed that the `images` array contains dynamic values, so I've used the `Dynamic` type in the function parameter. If you know the type of the `images` array, you can replace `Dynamic` with the actual type.