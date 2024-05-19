import haxe.ds.StringMap;
import three.textures.TextureLoader;
import three.loaders.TGALoader;
import three.math.Color;
import three.materials.Material;
import three.materials.MaterialParameters;
import three.materials.MMDToonMaterial;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Quaternion;
import three.math.Matrix4;
import three.scene.Scene;
import three.objects.Mesh;
import three.objects.BufferGeometry;
import three.geometries.BoxGeometry;
import three.geometries.SphereGeometry;
import three.geometries.IcosahedronGeometry;
import three.geometries.CylinderGeometry;
import three.geometries.OctahedronGeometry;
import three.geometries.TorusGeometry;
import three.geometries.TorusKnotGeometry;
import three.geometries.DodecahedronGeometry;
import three.geometries.RingGeometry;
import three.geometries.TubeGeometry;
import three.geometries.PlaneGeometry;
import three.geometries.SphereBufferGeometry;
import three.geometries.IcosahedronBufferGeometry;
import three.cameras.Camera;
import three.lights.Light;
import three.lights.AmbientLight;
import three.lights.DirectionalLight;
import three.lights.PointLight;
import three.lights.SpotLight;
import three.renderers.WebGLRenderer;
import three.renderers.Renderer;
import three.renderers.Projector;
import three.math.Box3;
import three.math.Frustum;
import three.objects.Line;
import three.objects.Lines;
import three.objects.LOD;
import three.objects.Sprite;
import three.objects.ParticleSystem;
import three.objects.SkinnedMesh;
import three.objects.InstancedMesh;
import three.objects.Bone;
import three.objects.ShadowCamera;
import three.objects.LensFlare;
import three.core.Geometry;
import three.core.BufferAttribute;
import three.math.Euler;

class MaterialBuilder {

	public var manager:LoaderManager;
	public var textureLoader:TextureLoader;
	public var tgaLoader:TGALoader;
	public var crossOrigin:String;
	public var resourcePath:String;

	public function new(manager:LoaderManager) {
		this.manager = manager;
		this.textureLoader = new TextureLoader(this.manager);
		this.tgaLoader = null; // lazy generation
		this.crossOrigin = 'anonymous';
		this.resourcePath = undefined;
	}

	public function setCrossOrigin(crossOrigin:String):MaterialBuilder {
		this.crossOrigin = crossOrigin;
		return this;
	}

	public function setResourcePath(resourcePath:String):MaterialBuilder {
		this.resourcePath = resourcePath;
		return this;
	}

	public function build(data:Dynamic, geometry:BufferGeometry):Array<MMDToonMaterial> {
		// implementation here
	}

	// private methods

	private function _getTGALoader():TGALoader {
		if (this.tgaLoader === null) {
			if (TGALoader === undefined) {
				throw new Error('THREE.MMDLoader: Import TGALoader');
			}
			this.tgaLoader = new TGALoader(this.manager);
		}
		return this.tgaLoader;
	}

	private function _isDefaultToonTexture(name:String):Bool {
		if (name.length !== 10) return false;
		return /toon(10|0[0-9])\.bmp$/.test(name);
	}

	private function _loadTexture(filePath:String, textures:StringMap<Dynamic>, params:Dynamic = null, onProgress:Dynamic, onError:Dynamic):Dynamic {
		// implementation here
	}

	private function _getRotatedImage(image:Dynamic):Dynamic {
		// implementation here
	}

	// Check if the partial image area used by the texture is transparent.
	private function _checkImageTransparency(map:Dynamic, geometry:Dynamic, groupIndex:Int) {
		// implementation here
	}

}