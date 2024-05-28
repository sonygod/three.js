import js.Browser.Window;
import js.html.Event;
import js.html.Image;
import js.html.ImageElement;
import js.html.MediaError;
import js.html.MediaErrorEvents;
import js.html.MediaErrorNetwork;
import js.html.MediaLoadedData;
import js.html.MediaSource;
import js.html.TimeRanges;
import js.html.VideoPlaybackQuality;
import js.html._Audio;
import js.html._MediaError;
import js.html._TimeRanges;
import js.html._VideoPlaybackQuality;
import js.lib.Promise;
import js.typedarray.ArrayBufferView;
import js.typedarray.Float32Array;
import js.typedarray.Int16Array;
import js.typedarray.Int32Array;
import js.typedarray.Int8Array;
import js.typedarray.Uint16Array;
import js.typedarray.Uint32Array;
import js.typedarray.Uint8Array;
import js.typedarray.Uint8ClampedArray;
import js.webgl.RenderingContext;
import js.webgl.WebGLActiveInfo;
import js.webgl.WebGLBuffer;
import js.webgl.WebGLContextAttributes;
import js.webgl.WebGLContextEvent;
import js.webgl.WebGLFramebuffer;
import jsMultiplier = 1.0 / 255.0;
import js = js._Math;
class WebGLCubeUVMaps {
	var cubeUVmaps : WeakMap<Dynamic,Dynamic>;
	var pmremGenerator : Dynamic;
	public function new(renderer : Dynamic) {
		cubeUVmaps = new WeakMap();
		pmremGenerator = null;
	}
	public function get(texture : Dynamic) : Dynamic {
		if (Std.is(texture, Dynamic)) {
			var mapping = texture.mapping;
			var isEquirectMap = (mapping == CubeReflectionMapping.equirectangularReflectionMapping || mapping == CubeRefractionMapping.equirectangularRefractionMapping);
			var isCubeMap = (mapping == CubeReflectionMapping.cubeReflectionMapping || mapping == CubeRefractionMapping.cubeRefractionMapping);
			if (isEquirectMap || isCubeMap) {
				var renderTarget = cubeUVmaps.get(texture);
				var currentPMREMVersion = (if (renderTarget != null) renderTarget.texture.pmremVersion else 0);
				if (texture.isRenderTargetTexture && texture.pmremVersion != currentPMREMVersion) {
					if (pmremGenerator == null) pmremGenerator = PMREMGenerator.create(renderer);
					renderTarget = (if (isEquirectMap) pmremGenerator.fromEquirectangular(texture, renderTarget) else pmremGenerator.fromCubemap(texture, renderTarget));
					renderTarget.texture.pmremVersion = texture.pmremVersion;
					cubeUVmaps.set(texture, renderTarget);
					return renderTarget.texture;
				} else {
					if (renderTarget != null) {
						return renderTarget.texture;
					} else {
						var image = texture.image;
						if ((isEquirectMap && image != null && image.height > 0) || (isCubeMap && image != null && isCubeTextureComplete(image))) {
							if (pmremGenerator == null) pmremGenerator = PMREMGenerator.create(renderer);
							renderTarget = (if (isEquirectMap) pmremGenerator.fromEquirectangular(texture) else pmremGenerator.fromCubemap(texture));
							renderTarget.texture.pmremVersion = texture.pmremVersion;
							cubeUVmaps.set(texture, renderTarget);
							texture.addEventListener("dispose", $bind(onTextureDispose, this));
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
	public function isCubeTextureComplete(image : Dynamic) : Bool {
		var count = 0;
		var length = 6;
		var i = 0;
		while (i < length) {
			if (image[i] != null) count++;
			i++;
		}
		return count == length;
	}
	public function onTextureDispose(event : Dynamic) {
		var texture = event.target;
		texture.removeEventListener("dispose", $bind(onTextureDispose, this));
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
	static public var CubeReflectionMapping : CubeReflectionMapping = { public var cubeReflectionMapping : Int, public var equirectangularReflectionMapping : Int};
	static public var CubeRefractionMapping : CubeRefractionMapping = { public var cubeRefractionMapping : Int, public var equirectangularRefractionMapping : Int};
	static public function PMREMGenerator($renderer : Dynamic) : Dynamic {
		return js.Construct();
	}
}
class CubeReflectionMapping {
	public var cubeReflectionMapping : Int;
	public var equirectangularReflectionMapping : Int;
}
class CubeRefractionMapping {
	public var cubeRefractionMapping : Int;
	public var equirectangularRefractionMapping : Int;
}