package three.loaders;

import three.core.Object3D;
import three.core.Group;
import three.core.Mesh;
import three.core.Sprite;
import three.core.Line;
import three.core.LineLoop;
import three.core.LineSegments;
import three.core.Points;
import three.core.Bone;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.loaders.MaterialLoader;
import three.loaders.BufferGeometryLoader;
import three.loaders.ImageLoader;
import three.loaders.LoadingManager;
import three.math.Box3;
import three.math.Sphere;
import three.math.Color;
import three.math.Vector3;
import three.textures.Texture;
import three.textures.CubeTexture;
import three.textures.DataTexture;
import three.animations.AnimationClip;
import three.loaders.Material;
import three.geometries.SphereGeometry;
import three.geometries.BoxGeometry;
import three.geometries.PlaneGeometry;
import three.geometries.CircleGeometry;
import three.geometries.ExtrudeGeometry;
import three.geometries.LatheGeometry;
import three.geometries.TorusGeometry;
import three.geometries.TorusKnotGeometry;
import three.geometries.ConvexGeometry;
import three.geometries.TeapotGeometry;
import three.geometries.OctahedronGeometry;
import three.geometries.IcosahedronGeometry;
import three.geometries.TetrahedronGeometry;
import three.geometries.DodecahedronGeometry;

class ObjectLoader extends Loader {
    public function new(manager:LoadingManager) {
        super(manager);
    }

    override public function load(url:String, onLoad:String->Void, onProgress:String->Float->Void, onError:String->Void) {
        // ...
    }

    async public function loadAsync(url:String, onProgress:String->Float->Void):Promise<Object3D> {
        // ...
    }

    function parseAnimations(json:Array<{}>, geometries:Map<String, {}>, materials:Map<String, {}>) {
        // ...
    }

    function parseShapes(json:Array<{}>) {
        // ...
    }

    function parseSkeletons(json:Array<{}>, object:Object3D) {
        // ...
    }

    function parseGeometries(json:Array<{}>, shapes:Map<String, {}>) {
        // ...
    }

    function parseMaterials(json:Array<{}>, textures:Map<String, {}>) {
        // ...
    }

    function parseTextures(json:Array<{}>, images:Map<String, {}>) {
        // ...
    }

    function parseImages(json:Array<{}>, onComplete:String->Void) {
        // ...
    }

    async function parseImagesAsync(json:Array<{}>) {
        // ...
    }

    function parseObject(data:{}, geometries:Map<String, {}>, materials:Map<String, {}>, textures:Map<String, {}>, animations:Map<String, {}>) {
        // ...
    }

    function bindSkeletons(object:Object3D, skeletons:Map<String, {}>) {
        // ...
    }
}