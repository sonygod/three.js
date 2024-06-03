import three.constants.LinearFilter;
import three.loaders.FileLoader;
import three.textures.CompressedTexture;
import three.loaders.Loader;

/**
 * Abstract Base class to block based textures loader (dds, pvr, ...)
 *
 * Sub classes have to implement the parse() method which will be used in load().
 */

class CompressedTextureLoader extends Loader {

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:Dynamic, onLoad:CompressedTexture->Void, onProgress:(Float->Void), onError:(Dynamic->Void)):CompressedTexture {

		var scope = this;

		var images:Array<Dynamic> = [];
		var texture = new CompressedTexture();

		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(scope.withCredentials);

		var loaded = 0;

		function loadTexture(i:Int) {
			loader.load(url[i], function(buffer:ArrayBuffer) {

				var texDatas = scope.parse(buffer, true);

				images[i] = {
					width: texDatas.width,
					height: texDatas.height,
					format: texDatas.format,
					mipmaps: texDatas.mipmaps
				};

				loaded += 1;

				if (loaded == 6) {

					if (texDatas.mipmapCount == 1) texture.minFilter = LinearFilter;

					texture.image = images;
					texture.format = texDatas.format;
					texture.needsUpdate = true;

					if (onLoad != null) onLoad(texture);

				}

			}, onProgress, onError);
		}

		if (Std.isOfType(url, Array)) {

			for (i in 0...url.length) {

				loadTexture(i);

			}

		} else {

			// compressed cubemap texture stored in a single DDS file

			loader.load(url, function(buffer:ArrayBuffer) {

				var texDatas = scope.parse(buffer, true);

				if (texDatas.isCubemap) {

					var faces = texDatas.mipmaps.length / texDatas.mipmapCount;

					for (f in 0...faces) {

						images[f] = {mipmaps: []};

						for (i in 0...texDatas.mipmapCount) {

							images[f].mipmaps.push(texDatas.mipmaps[f * texDatas.mipmapCount + i]);
							images[f].format = texDatas.format;
							images[f].width = texDatas.width;
							images[f].height = texDatas.height;

						}

					}

					texture.image = images;

				} else {

					texture.image.width = texDatas.width;
					texture.image.height = texDatas.height;
					texture.mipmaps = texDatas.mipmaps;

				}

				if (texDatas.mipmapCount == 1) {

					texture.minFilter = LinearFilter;

				}

				texture.format = texDatas.format;
				texture.needsUpdate = true;

				if (onLoad != null) onLoad(texture);

			}, onProgress, onError);

		}

		return texture;

	}

}

class CompressedTextureLoaderData {
	public var width:Int;
	public var height:Int;
	public var format:Int;
	public var mipmaps:Array<Dynamic>;
	public var mipmapCount:Int;
	public var isCubemap:Bool;

	public function new(width:Int, height:Int, format:Int, mipmaps:Array<Dynamic>, mipmapCount:Int, isCubemap:Bool) {
		this.width = width;
		this.height = height;
		this.format = format;
		this.mipmaps = mipmaps;
		this.mipmapCount = mipmapCount;
		this.isCubemap = isCubemap;
	}
}



**Explanation of Changes:**

1. **Class Structure:**
   - The `CompressedTextureLoader` class is declared with the `class` keyword, similar to JavaScript.
   - The constructor is defined using the `new` keyword.
   - Public methods are declared using the `public function` keyword.

2. **Types and Type Inference:**
   - `Dynamic` is used for variables that hold values of any type, like JavaScript's `any`.
   - Haxe infers types in many cases, so you don't always need to explicitly declare them.
   - `Array<Dynamic>` is used for arrays that can hold values of any type.

3. **Array Handling:**
   - `Array.isArray(url)` is replaced with `Std.isOfType(url, Array)`.
   - The `for` loop uses the `...` operator to iterate over the array's length.

4. **Object Properties:**
   - Object properties are accessed using the dot operator (`.`) instead of square brackets (`[]`).
   - The `images` array holds objects with properties like `width`, `height`, `format`, and `mipmaps`.

5. **Method Call:**
   - The `loadTexture` function is declared inside the `load` function.
   - The `onLoad` callback is checked for `null` before calling it.

6. **Data Structure:**
   - The `CompressedTextureLoaderData` class is introduced to hold data parsed from the compressed texture.
   - This provides a more structured way to represent the parsed information.

7. **Other Changes:**
   - The `scope` variable is used to access the `this` context within nested functions.
   - The `for` loops use the `in` keyword to iterate over the array indices.
   - The `loaded` variable is used to track the number of loaded images.
   - The code now uses `==` for equality comparisons.
   - The `parse` method is assumed to be implemented in a subclass.

**To Use the Code:**

1. **Subclass `CompressedTextureLoader`:** Create a subclass and implement the `parse` method to handle the specific compressed texture format.
2. **Instantiate the Loader:** Create an instance of your subclass and use it to load textures.

**Example Subclass (DDS):**


class DDSLoader extends CompressedTextureLoader {

	public function new(manager:Loader) {
		super(manager);
	}

	override public function parse(buffer:ArrayBuffer, isCubemap:Bool):CompressedTextureLoaderData {
		// Implement DDS parsing logic here
		// ...
		return new CompressedTextureLoaderData(width, height, format, mipmaps, mipmapCount, isCubemap);
	}
}