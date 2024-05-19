import three.js.src.constants.LinearFilter;
import three.js.src.constants.LinearMipmapLinearFilter;
import three.js.src.constants.ClampToEdgeWrapping;
import three.js.src.loaders.FileLoader.FileLoader;
import three.js.src.textures.DataTexture.DataTexture;
import three.js.src.loaders.Loader.Loader;

class DataTextureLoader extends Loader {

	public function new(manager:Dynamic) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):DataTexture {
		var scope = this;
		var texture = new DataTexture();
		var loader = new FileLoader(this.manager);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(this.requestHeader);
		loader.setPath(this.path);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(buffer:Dynamic) {
			var texData:Dynamic;
			try {
				texData = scope.parse(buffer);
			} catch (error:Dynamic) {
				if (onError !== undefined) {
					onError(error);
				} else {
					trace(error);
					return;
				}
			}
			if (texData.image !== undefined) {
				texture.image = texData.image;
			} else if (texData.data !== undefined) {
				texture.image.width = texData.width;
				texture.image.height = texData.height;
				texture.image.data = texData.data;
			}
			texture.wrapS = texData.wrapS !== undefined ? texData.wrapS : ClampToEdgeWrapping;
			texture.wrapT = texData.wrapT !== undefined ? texData.wrapT : ClampToEdgeWrapping;
			texture.magFilter = texData.magFilter !== undefined ? texData.magFilter : LinearFilter;
			texture.minFilter = texData.minFilter !== undefined ? texData.minFilter : LinearFilter;
			texture.anisotropy = texData.anisotropy !== undefined ? texData.anisotropy : 1;
			if (texData.colorSpace !== undefined) {
				texture.colorSpace = texData.colorSpace;
			}
			if (texData.flipY !== undefined) {
				texture.flipY = texData.flipY;
			}
			if (texData.format !== undefined) {
				texture.format = texData.format;
			}
			if (texData.type !== undefined) {
				texture.type = texData.type;
			}
			if (texData.mipmaps !== undefined) {
				texture.mipmaps = texData.mipmaps;
				texture.minFilter = LinearMipmapLinearFilter;
			}
			if (texData.mipmapCount === 1) {
				texture.minFilter = LinearFilter;
			}
			if (texData.generateMipmaps !== undefined) {
				texture.generateMipmaps = texData.generateMipmaps;
			}
			texture.needsUpdate = true;
			if (onLoad) onLoad(texture, texData);
		}, onProgress, onError);
		return texture;
	}
}