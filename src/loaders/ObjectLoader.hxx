import three.Loader;
import three.LoaderUtils;
import three.ImageLoader;
import three.FileLoader;
import three.BufferGeometryLoader;
import three.MaterialLoader;
import three.LoadingManager;
import three.AnimationClip;
import three.InstancedBufferAttribute;
import three.Color;
import three.Object3D;
import three.Group;
import three.InstancedMesh;
import three.BatchedMesh;
import three.Sprite;
import three.Points;
import three.Line;
import three.LineLoop;
import three.LineSegments;
import three.LOD;
import three.Mesh;
import three.SkinnedMesh;
import three.Bone;
import three.Skeleton;
import three.Shape;
import three.Fog;
import three.FogExp2;
import three.HemisphereLight;
import three.SpotLight;
import three.PointLight;
import three.DirectionalLight;
import three.AmbientLight;
import three.RectAreaLight;
import three.LightProbe;
import three.OrthographicCamera;
import three.PerspectiveCamera;
import three.Scene;
import three.CubeTexture;
import three.Texture;
import three.Source;
import three.DataTexture;
import three.Box3;
import three.Sphere;
import three.utils.getTypedArray;
import three.constants.*;
import three.geometries.Geometries;

class ObjectLoader extends Loader {

    public function new(manager:LoadingManager) {
        super(manager);
    }

    public function load(url:String, onLoad:(Object3D)->Void, onProgress:(ProgressEvent)->Void, onError:(Error)->Void):Void {
        var scope = this;

        var path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
        this.resourcePath = this.resourcePath || path;

        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function (text:String) {

            var json:Dynamic = null;

            try {
                json = haxe.Json.parse(text);
            } catch (error:Dynamic) {
                if (onError != null) onError(error);
                trace('THREE:ObjectLoader: Can\'t parse ' + url + '.', error.message);
                return;
            }

            var metadata = json.metadata;

            if (metadata == null || metadata.type == null || metadata.type.toLowerCase() == 'geometry') {
                if (onError != null) onError(new Error('THREE.ObjectLoader: Can\'t load ' + url));
                trace('THREE.ObjectLoader: Can\'t load ' + url);
                return;
            }

            scope.parse(json, onLoad);

        }, onProgress, onError);
    }

    public function loadAsync(url:String, onProgress:(ProgressEvent)->Void):Promise<Object3D> {
        var scope = this;

        var path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
        this.resourcePath = this.resourcePath || path;

        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);

        return loader.loadAsync(url, onProgress).then(function (text:String) {

            var json:Dynamic = haxe.Json.parse(text);

            var metadata = json.metadata;

            if (metadata == null || metadata.type == null || metadata.type.toLowerCase() == 'geometry') {
                throw new Error('THREE.ObjectLoader: Can\'t load ' + url);
            }

            return scope.parseAsync(json);

        });
    }

    public function parse(json:Dynamic, onLoad:(Object3D)->Void):Object3D {

        var animations = this.parseAnimations(json.animations);
        var shapes = this.parseShapes(json.shapes);
        var geometries = this.parseGeometries(json.geometries, shapes);

        var images = this.parseImages(json.images, function () {
            if (onLoad != null) onLoad(object);
        });

        var textures = this.parseTextures(json.textures, images);
        var materials = this.parseMaterials(json.materials, textures);

        var object = this.parseObject(json.object, geometries, materials, textures, animations);
        var skeletons = this.parseSkeletons(json.skeletons, object);

        this.bindSkeletons(object, skeletons);

        if (onLoad != null) {
            var hasImages = false;

            for (image in images) {
                if (images[image].data instanceof HTMLImageElement) {
                    hasImages = true;
                    break;
                }
            }

            if (!hasImages) onLoad(object);
        }

        return object;
    }

    public function parseAsync(json:Dynamic):Promise<Object3D> {
        var scope = this;

        return Promise.all([
            this.parseAnimations(json.animations),
            this.parseShapes(json.shapes),
            this.parseGeometries(json.geometries, shapes),
            this.parseImagesAsync(json.images),
            this.parseTextures(json.textures, images),
            this.parseMaterials(json.materials, textures),
            this.parseObject(json.object, geometries, materials, textures, animations),
            this.parseSkeletons(json.skeletons, object)
        ]).then(function (results) {
            var animations = results[0];
            var shapes = results[1];
            var geometries = results[2];
            var images = results[3];
            var textures = results[4];
            var materials = results[5];
            var object = results[6];
            var skeletons = results[7];

            scope.bindSkeletons(object, skeletons);

            return object;
        });
    }

    // ... rest of the methods ...
}