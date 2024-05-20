import three.js.src.renderers.webgl.WebGLCubeUVMaps.*;
import three.js.src.constants.*;
import three.js.src.extras.PMREMGenerator.*;

class WebGLCubeUVMaps {

	var cubeUVmaps:WeakMap<Texture, RenderTarget>;
	var pmremGenerator:PMREMGenerator;

	public function new(renderer:Renderer) {
		cubeUVmaps = new WeakMap();
		pmremGenerator = null;
	}

	public function get(texture:Texture):Texture {
		if (texture != null && texture.isTexture) {
			var mapping = texture.mapping;
			var isEquirectMap = (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping);
			var isCubeMap = (mapping == CubeReflectionMapping || mapping == CubeRefractionMapping);
			if (isEquirectMap || isCubeMap) {
				var renderTarget = cubeUVmaps.get(texture);
				var currentPMREMVersion = renderTarget != null ? renderTarget.texture.pmremVersion : 0;
				if (texture.isRenderTargetTexture && texture.pmremVersion != currentPMREMVersion) {
					if (pmremGenerator == null) pmremGenerator = new PMREMGenerator(renderer);
					renderTarget = isEquirectMap ? pmremGenerator.fromEquirectangular(texture, renderTarget) : pmremGenerator.fromCubemap(texture, renderTarget);
					renderTarget.texture.pmremVersion = texture.pmremVersion;
					cubeUVmaps.set(texture, renderTarget);
					return renderTarget.texture;
				} else {
					if (renderTarget != null) {
						return renderTarget.texture;
					} else {
						var image = texture.image;
						if ((isEquirectMap && image != null && image.height > 0) || (isCubeMap && image != null && isCubeTextureComplete(image))) {
							if (pmremGenerator == null) pmremGenerator = new PMREMGenerator(renderer);
							renderTarget = isEquirectMap ? pmremGenerator.fromEquirectangular(texture) : pmremGenerator.fromCubemap(texture);
							renderTarget.texture.pmremVersion = texture.pmremVersion;
							cubeUVmaps.set(texture, renderTarget);
							texture.addEventListener(Event.DISPOSE, onTextureDispose);
							return renderTarget.texture;
						} else {
							return null;
						}
					}
				}
			}
		}
		return texture;
	}

	private function isCubeTextureComplete(image:Dynamic):Bool {
		var count = 0;
		var length = 6;
		for (i in 0...length) {
			if (image[i] != null) count++;
		}
		return count == length;
	}

	private function onTextureDispose(event:Event) {
		var texture = cast(event.target, Texture);
		texture.removeEventListener(Event.DISPOSE, onTextureDispose);
		var cubemapUV = cubeUVmaps.get(texture);
		if (cubemapUV != null) {
			cubeUVmaps.delete(texture);
			cubemapUV.dispose();
		}
	}

	public function dispose() {
		cubeUVmaps = new WeakMap();
		if (pmremGenerator != null) {
			pmremGenerator.dispose();
			pmremGenerator = null;
		}
	}
}