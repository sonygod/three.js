import three.js.src.constants.UVMapping;
import three.js.src.constants.CubeReflectionMapping;
import three.js.src.constants.CubeRefractionMapping;
import three.js.src.constants.EquirectangularReflectionMapping;
import three.js.src.constants.EquirectangularRefractionMapping;
import three.js.src.constants.CubeUVReflectionMapping;
import three.js.src.constants.RepeatWrapping;
import three.js.src.constants.ClampToEdgeWrapping;
import three.js.src.constants.MirroredRepeatWrapping;
import three.js.src.constants.NearestFilter;
import three.js.src.constants.NearestMipmapNearestFilter;
import three.js.src.constants.NearestMipmapLinearFilter;
import three.js.src.constants.LinearFilter;
import three.js.src.constants.LinearMipmapNearestFilter;
import three.js.src.constants.LinearMipmapLinearFilter;
import three.js.src.core.InstancedBufferAttribute;
import three.js.src.math.Color;
import three.js.src.core.Object3D;
import three.js.src.objects.Group;
import three.js.src.objects.InstancedMesh;
import three.js.src.objects.BatchedMesh;
import three.js.src.objects.Sprite;
import three.js.src.objects.Points;
import three.js.src.objects.Line;
import three.js.src.objects.LineLoop;
import three.js.src.objects.LineSegments;
import three.js.src.objects.LOD;
import three.js.src.objects.Mesh;
import three.js.src.objects.SkinnedMesh;
import three.js.src.objects.Bone;
import three.js.src.objects.Skeleton;
import three.js.src.extras.core.Shape;
import three.js.src.scenes.Fog;
import three.js.src.scenes.FogExp2;
import three.js.src.lights.HemisphereLight;
import three.js.src.lights.SpotLight;
import three.js.src.lights.PointLight;
import three.js.src.lights.DirectionalLight;
import three.js.src.lights.AmbientLight;
import three.js.src.lights.RectAreaLight;
import three.js.src.lights.LightProbe;
import three.js.src.cameras.OrthographicCamera;
import three.js.src.cameras.PerspectiveCamera;
import three.js.src.scenes.Scene;
import three.js.src.textures.CubeTexture;
import three.js.src.textures.Texture;
import three.js.src.textures.Source;
import three.js.src.textures.DataTexture;
import three.js.src.loaders.ImageLoader;
import three.js.src.loaders.LoadingManager;
import three.js.src.animation.AnimationClip;
import three.js.src.loaders.MaterialLoader;
import three.js.src.loaders.LoaderUtils;
import three.js.src.loaders.BufferGeometryLoader;
import three.js.src.loaders.Loader;
import three.js.src.loaders.FileLoader;
import three.js.src.geometries.Geometries;
import three.js.src.utils.getTypedArray;
import three.js.src.math.Box3;
import three.js.src.math.Sphere;

class ObjectLoader extends Loader {

	public function new(manager:LoadingManager) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
		// ...
	}

	public function loadAsync(url:String, onProgress:Dynamic) {
		// ...
	}

	public function parse(json:Dynamic, onLoad:Dynamic) {
		// ...
	}

	public function parseAsync(json:Dynamic) {
		// ...
	}

	public function parseShapes(json:Dynamic) {
		// ...
	}

	public function parseSkeletons(json:Dynamic, object:Object3D) {
		// ...
	}

	public function parseGeometries(json:Dynamic, shapes:Dynamic) {
		// ...
	}

	public function parseMaterials(json:Dynamic, textures:Dynamic) {
		// ...
	}

	public function parseAnimations(json:Dynamic) {
		// ...
	}

	public function parseImages(json:Dynamic, onLoad:Dynamic) {
		// ...
	}

	public function parseImagesAsync(json:Dynamic) {
		// ...
	}

	public function parseTextures(json:Dynamic, images:Dynamic) {
		// ...
	}

	public function parseObject(data:Dynamic, geometries:Dynamic, materials:Dynamic, textures:Dynamic, animations:Dynamic) {
		// ...
	}

	public function bindSkeletons(object:Object3D, skeletons:Dynamic) {
		// ...
	}

}

const TEXTURE_MAPPING = {
	UVMapping: UVMapping,
	CubeReflectionMapping: CubeReflectionMapping,
	CubeRefractionMapping: CubeRefractionMapping,
	EquirectangularReflectionMapping: EquirectangularReflectionMapping,
	EquirectangularRefractionMapping: EquirectangularRefractionMapping,
	CubeUVReflectionMapping: CubeUVReflectionMapping
};

const TEXTURE_WRAPPING = {
	RepeatWrapping: RepeatWrapping,
	ClampToEdgeWrapping: ClampToEdgeWrapping,
	MirroredRepeatWrapping: MirroredRepeatWrapping
};

const TEXTURE_FILTER = {
	NearestFilter: NearestFilter,
	NearestMipmapNearestFilter: NearestMipmapNearestFilter,
	NearestMipmapLinearFilter: NearestMipmapLinearFilter,
	LinearFilter: LinearFilter,
	LinearMipmapNearestFilter: LinearMipmapNearestFilter,
	LinearMipmapLinearFilter: LinearMipmapLinearFilter
};

export { ObjectLoader };