import haxe.ds.StringMap;
import three.core.InstancedBufferAttribute;
import three.math.Color;
import three.core.Object3D;
import three.objects.Group;
import three.objects.InstancedMesh;
import three.objects.BatchedMesh;
import three.objects.Sprite;
import three.objects.Points;
import three.objects.Line;
import three.objects.LineLoop;
import three.objects.LineSegments;
import three.objects.LOD;
import three.objects.Mesh;
import three.objects.SkinnedMesh;
import three.objects.Bone;
import three.objects.Shape;
import three.scenes.Fog;
import three.scenes.FogExp2;
import three.lights.HemisphereLight;
import three.lights.SpotLight;
import three.lights.PointLight;
import three.lights.DirectionalLight;
import three.lights.AmbientLight;
import three.lights.RectAreaLight;
import three.lights.LightProbe;
import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.scenes.Scene;
import three.textures.CubeTexture;
import three.textures.Texture;
import three.textures.Source;
import three.textures.DataTexture;
import three.loaders.ImageLoader;
import three.loaders.LoadingManager;
import three.animation.AnimationClip;
import three.loaders.MaterialLoader;
import three.loaders.LoaderUtils;
import three.loaders.BufferGeometryLoader;
import three.loaders.Loader;
import three.loaders.FileLoader;
import three.geometries.Geometries;
import three.math.Box3;
import three.math.Sphere;

class ObjectLoader extends Loader {

	public function new(manager:LoadingManager) {
		super(manager);
	}

	public function load(url:String, onLoad:Void -> Void, onProgress:Int -> Void, onError:Dynamic -> Void):Void {
		var scope = this;

		var path = (this.path == '') ? LoaderUtils.extractUrlBase(url) : this.path;
		this.resourcePath = this.resourcePath != null ? this.resourcePath : path;

		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(text) {

			var json = null;

			try {

				json = JSON.parse(text);

			} catch(error) {

				if (onError != null) onError(error);

				console.error("THREE:ObjectLoader: Can't parse " + url + ". " + error.message);

				return;

			}

			var metadata = json.metadata;

			if (metadata == null || metadata.type == null || metadata.type.toLowerCase() == "geometry") {

				if (onError != null) onError(new Error("THREE.ObjectLoader: Can't load " + url));

				console.error("THREE.ObjectLoader: Can't load " + url);
				return;

			}

			scope.parse(json, onLoad);

		}, onProgress, onError);
	}

	public function parse(json:Dynamic, onLoad:Void -> Void):Void {
		// TODO: Implement parse method
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