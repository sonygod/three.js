import three.js.src.renderers.webgl.WebGLCubeRenderTarget;
import three.js.src.constants.CubeReflectionMapping;
import three.js.src.constants.CubeRefractionMapping;
import three.js.src.constants.EquirectangularReflectionMapping;
import three.js.src.constants.EquirectangularRefractionMapping;

class WebGLCubeMaps {

	var cubemaps:haxe.ds.WeakMap<Dynamic, Dynamic>;
	var renderer:Dynamic;

	public function new(renderer:Dynamic) {
		this.renderer = renderer;
		this.cubemaps = new haxe.ds.WeakMap();
	}

	public function get(texture:Dynamic):Dynamic {
		if (texture != null && texture.isTexture) {
			var mapping = texture.mapping;
			if (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping) {
				if (this.cubemaps.has(texture)) {
					var cubemap = this.cubemaps.get(texture).texture;
					return this.mapTextureMapping(cubemap, texture.mapping);
				} else {
					var image = texture.image;
					if (image != null && image.height > 0) {
						var renderTarget = new WebGLCubeRenderTarget(image.height);
						renderTarget.fromEquirectangularTexture(this.renderer, texture);
						this.cubemaps.set(texture, renderTarget);
						texture.addEventListener('dispose', this.onTextureDispose);
						return this.mapTextureMapping(renderTarget.texture, texture.mapping);
					} else {
						return null;
					}
				}
			}
		}
		return texture;
	}

	public function onTextureDispose(event:Dynamic):Void {
		var texture = event.target;
		texture.removeEventListener('dispose', this.onTextureDispose);
		var cubemap = this.cubemaps.get(texture);
		if (cubemap != null) {
			this.cubemaps.delete(texture);
			cubemap.dispose();
		}
	}

	public function dispose():Void {
		this.cubemaps = new haxe.ds.WeakMap();
	}

	private function mapTextureMapping(texture:Dynamic, mapping:Dynamic):Dynamic {
		if (mapping == EquirectangularReflectionMapping) {
			texture.mapping = CubeReflectionMapping;
		} else if (mapping == EquirectangularRefractionMapping) {
			texture.mapping = CubeRefractionMapping;
		}
		return texture;
	}
}