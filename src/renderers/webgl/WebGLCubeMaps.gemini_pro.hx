import js.html.CanvasElement;
import js.html.ImageElement;
import js.html.ImageData;
import js.html.webgl.WebGLRenderingContext;
import js.html.webgl.WebGLTexture;
import js.html.webgl.WebGLUniformLocation;

import three.constants.CubeReflectionMapping;
import three.constants.CubeRefractionMapping;
import three.constants.EquirectangularReflectionMapping;
import three.constants.EquirectangularRefractionMapping;
import three.textures.Texture;
import three.renderers.WebGLRenderer;
import three.renderers.WebGLCubeRenderTarget;

class WebGLCubeMaps {

	public var cubemaps:WeakMap<Texture, WebGLCubeRenderTarget>;

	public function new(renderer:WebGLRenderer) {
		this.cubemaps = new WeakMap();
	}

	public function mapTextureMapping(texture:Texture, mapping:Int):Texture {

		switch(mapping) {
		case EquirectangularReflectionMapping:
			texture.mapping = CubeReflectionMapping;
			break;
		case EquirectangularRefractionMapping:
			texture.mapping = CubeRefractionMapping;
			break;
		}

		return texture;
	}

	public function get(texture:Texture):Texture {

		if(texture != null && texture.isTexture) {

			var mapping = texture.mapping;

			if(mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping) {

				if(cubemaps.has(texture)) {

					var cubemap = cubemaps.get(texture).texture;
					return mapTextureMapping(cubemap, texture.mapping);

				} else {

					var image:ImageElement = texture.image;

					if(image != null && image.height > 0) {

						var renderTarget = new WebGLCubeRenderTarget(image.height);
						renderTarget.fromEquirectangularTexture(renderer, texture);
						cubemaps.set(texture, renderTarget);

						texture.addEventListener('dispose', onTextureDispose);

						return mapTextureMapping(renderTarget.texture, texture.mapping);

					} else {

						// image not yet ready. try the conversion next frame

						return null;

					}

				}

			}

		}

		return texture;
	}

	public function onTextureDispose(event:Dynamic) {

		var texture = cast texture.target;

		texture.removeEventListener('dispose', onTextureDispose);

		var cubemap = cubemaps.get(texture);

		if(cubemap != null) {

			cubemaps.delete(texture);
			cubemap.dispose();

		}

	}

	public function dispose() {

		cubemaps = new WeakMap();

	}

}