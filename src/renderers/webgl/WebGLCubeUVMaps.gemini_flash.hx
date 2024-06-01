import haxe.WeakMap;
import three.extras.PMREMGenerator;
import three.constants.CubeReflectionMapping;
import three.constants.CubeRefractionMapping;
import three.constants.EquirectangularReflectionMapping;
import three.constants.EquirectangularRefractionMapping;
import three.textures.Texture;
import three.renderers.WebGLRenderer;
import three.materials.Material;

class WebGLCubeUVMaps {

	private var cubeUVmaps:WeakMap<Texture, dynamic>;
	private var pmremGenerator:PMREMGenerator;

	public function new(renderer:WebGLRenderer) {
		this.cubeUVmaps = new WeakMap();
		this.pmremGenerator = null;
	}

	public function get(texture:Texture):Texture {
		if (texture != null && texture.isTexture) {
			var mapping = texture.mapping;
			var isEquirectMap = (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping);
			var isCubeMap = (mapping == CubeReflectionMapping || mapping == CubeRefractionMapping);
			if (isEquirectMap || isCubeMap) {
				var renderTarget = this.cubeUVmaps.get(texture);
				var currentPMREMVersion = renderTarget != null ? renderTarget.texture.pmremVersion : 0;
				if (texture.isRenderTargetTexture && texture.pmremVersion != currentPMREMVersion) {
					if (this.pmremGenerator == null) {
						this.pmremGenerator = new PMREMGenerator(renderer);
					}
					renderTarget = isEquirectMap ? this.pmremGenerator.fromEquirectangular(texture, renderTarget) : this.pmremGenerator.fromCubemap(texture, renderTarget);
					renderTarget.texture.pmremVersion = texture.pmremVersion;
					this.cubeUVmaps.set(texture, renderTarget);
					return renderTarget.texture;
				} else {
					if (renderTarget != null) {
						return renderTarget.texture;
					} else {
						var image = texture.image;
						if ((isEquirectMap && image != null && image.height > 0) || (isCubeMap && image != null && this.isCubeTextureComplete(image))) {
							if (this.pmremGenerator == null) {
								this.pmremGenerator = new PMREMGenerator(renderer);
							}
							renderTarget = isEquirectMap ? this.pmremGenerator.fromEquirectangular(texture) : this.pmremGenerator.fromCubemap(texture);
							renderTarget.texture.pmremVersion = texture.pmremVersion;
							this.cubeUVmaps.set(texture, renderTarget);
							texture.addEventListener('dispose', this.onTextureDispose);
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

	private function isCubeTextureComplete(image:Array<Dynamic>):Bool {
		var count = 0;
		var length = 6;
		for (i in 0...length) {
			if (image[i] != null) {
				count++;
			}
		}
		return count == length;
	}

	private function onTextureDispose(event:Dynamic) {
		var texture = cast(event.target, Texture);
		texture.removeEventListener('dispose', this.onTextureDispose);
		var cubemapUV = this.cubeUVmaps.get(texture);
		if (cubemapUV != null) {
			this.cubeUVmaps.delete(texture);
			cubemapUV.dispose();
		}
	}

	public function dispose() {
		this.cubeUVmaps = new WeakMap();
		if (this.pmremGenerator != null) {
			this.pmremGenerator.dispose();
			this.pmremGenerator = null;
		}
	}

}