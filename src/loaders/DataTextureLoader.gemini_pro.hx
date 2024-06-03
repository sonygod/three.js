import haxe.io.Bytes;
import three.loaders.Loader;
import three.textures.DataTexture;
import three.constants.Constants;

/**
 * Abstract Base class to load generic binary textures formats (rgbe, hdr, ...)
 *
 * Sub classes have to implement the parse() method which will be used in load().
 */
class DataTextureLoader extends Loader {

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):DataTexture {
		var texture = new DataTexture();
		var loader = new FileLoader(manager);
		loader.setResponseType(FileLoader.ARRAYBUFFER);
		loader.setRequestHeader(requestHeader);
		loader.setPath(path);
		loader.setWithCredentials(withCredentials);
		loader.load(url, function(buffer:Bytes) {
			var texData:Dynamic;
			try {
				texData = parse(buffer);
			} catch (error:Dynamic) {
				if (onError != null) {
					onError(error);
				} else {
					trace(error);
				}
				return;
			}

			if (texData.image != null) {
				texture.image = texData.image;
			} else if (texData.data != null) {
				texture.image.width = texData.width;
				texture.image.height = texData.height;
				texture.image.data = texData.data;
			}

			texture.wrapS = texData.wrapS != null ? texData.wrapS : Constants.ClampToEdgeWrapping;
			texture.wrapT = texData.wrapT != null ? texData.wrapT : Constants.ClampToEdgeWrapping;

			texture.magFilter = texData.magFilter != null ? texData.magFilter : Constants.LinearFilter;
			texture.minFilter = texData.minFilter != null ? texData.minFilter : Constants.LinearFilter;

			texture.anisotropy = texData.anisotropy != null ? texData.anisotropy : 1;

			if (texData.colorSpace != null) {
				texture.colorSpace = texData.colorSpace;
			}

			if (texData.flipY != null) {
				texture.flipY = texData.flipY;
			}

			if (texData.format != null) {
				texture.format = texData.format;
			}

			if (texData.type != null) {
				texture.type = texData.type;
			}

			if (texData.mipmaps != null) {
				texture.mipmaps = texData.mipmaps;
				texture.minFilter = Constants.LinearMipmapLinearFilter;
			}

			if (texData.mipmapCount == 1) {
				texture.minFilter = Constants.LinearFilter;
			}

			if (texData.generateMipmaps != null) {
				texture.generateMipmaps = texData.generateMipmaps;
			}

			texture.needsUpdate = true;

			if (onLoad != null) onLoad(texture, texData);
		}, onProgress, onError);

		return texture;
	}

	/**
	 * Parse the data, create the image and return it.
	 *
	 * @param {ArrayBuffer} buffer
	 * @return {Object}
	 */
	public function parse(buffer:Bytes):Dynamic {
		throw "parse() not implemented";
	}

}


**Explanation:**

1. **Imports:** We import the necessary classes:
   - `haxe.io.Bytes` for handling binary data.
   - `three.loaders.Loader` for the base loader class.
   - `three.textures.DataTexture` for the texture object.
   - `three.constants.Constants` for texture filtering and wrapping constants.

2. **Class Definition:** The `DataTextureLoader` class extends `Loader` and defines its constructor.

3. **`load()` Method:**
   - Creates a `DataTexture` object.
   - Creates a `FileLoader` object with the provided `manager`.
   - Sets the response type to `FileLoader.ARRAYBUFFER` to load binary data.
   - Calls `parse()` to handle the loaded data and return an object containing texture information.
   - Sets texture properties like `wrapS`, `wrapT`, `magFilter`, `minFilter`, etc. based on the parsed data.
   - Sets `needsUpdate` to `true` to signal that the texture needs to be updated.
   - Calls the `onLoad` callback with the texture object and parsed data.

4. **`parse()` Method:** This method is abstract and needs to be implemented by subclasses. It's responsible for parsing the binary data and returning an object containing the texture information.

**Key Changes:**

- **Data Type:** The `buffer` parameter in the `parse()` method is of type `Bytes` in Haxe, representing binary data.
- **`trace()` instead of `console.error()`:** The `trace()` function is used for logging in Haxe.
- **Object Handling:** Haxe uses dynamic types to represent JavaScript objects. This allows us to work with the parsed data without needing to define specific data structures.
- **Abstract `parse()` Method:** Haxe requires abstract methods to be declared with the `abstract` keyword.

**Usage:**

To use the `DataTextureLoader` class, you need to create a subclass and implement the `parse()` method:


class MyDataTextureLoader extends DataTextureLoader {

	public function new(manager:Loader) {
		super(manager);
	}

	override public function parse(buffer:Bytes):Dynamic {
		// Your code to parse the buffer and return the texture information
	}

}


Then, you can use the subclass to load the texture:


var loader = new MyDataTextureLoader(manager);
loader.load("path/to/texture.ext", function(texture:DataTexture, data:Dynamic) {
	// Use the texture
});