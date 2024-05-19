package three.loaders;

import three.constants.UVMapping;
import three.constants.CubeReflectionMapping;
import three.constants.CubeRefractionMapping;
import three.constants.EquirectangularReflectionMapping;
import three.constants.EquirectangularRefractionMapping;
import three.constants.CubeUVReflectionMapping;

import three.constants.RepeatWrapping;
import three.constants.ClampToEdgeWrapping;
import three.constants.MirroredRepeatWrapping;

import three.constants.NearestFilter;
import three.constants.NearestMipmapNearestFilter;
import three.constants.NearestMipmapLinearFilter;
import three.constants.LinearFilter;
import three.constants.LinearMipmapNearestFilter;
import three.constants.LinearMipmapLinearFilter;

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
import three.objects.Skeleton;
import three.extras.core.Shape;
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
import three.utils.getTypedArray;
import three.math.Box3;
import three.math.Sphere;

class ObjectLoader extends Loader {
    public function new(manager:LoadingManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Void->Void, onProgress:Float->Void, onError:String->Void) {
        var path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
        this.resourcePath = this.resourcePath || path;

        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(text:String) {
            var json = null;
            try {
                json = Json.parse(text);
            } catch (e:Dynamic) {
                if (onError != null) onError(e);
                trace('THREE.ObjectLoader: Can\'t parse ' + url, e.message);
                return;
            }

            var metadata = json.metadata;
            if (metadata == null || metadata.type == null || metadata.type.toLowerCase() == 'geometry') {
                if (onError != null) onError(new Error('THREE.ObjectLoader: Can\'t load ' + url));
                trace('THREE.ObjectLoader: Can\'t load ' + url);
                return;
            }

            this.parse(json, onLoad);
        }, onProgress, onError);
    }

    public function loadAsync(url:String, onProgress:Float->Void):Promise<Void> {
        var path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
        this.resourcePath = this.resourcePath || path;

        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);

        return loader.loadAsync(url, onProgress).then(function(text:String) {
            var json = Json.parse(text);
            var metadata = json.metadata;
            if (metadata == null || metadata.type == null || metadata.type.toLowerCase() == 'geometry') {
                throw new Error('THREE.ObjectLoader: Can\'t load ' + url);
            }

            return this.parseAsync(json);
        });
    }

    private function parse(json:Dynamic, onLoad:Void->Void) {
        var animations = this.parseAnimations(json.animations);
        var shapes = this.parseShapes(json.shapes);
        var geometries = this.parseGeometries(json.geometries, shapes);

        var images = this.parseImages(json.images, function() {
            if (onLoad != null) onLoad();
        });

        var textures = this.parseTextures(json.textures, images);
        var materials = this.parseMaterials(json.materials, textures);

        var object = this.parseObject(json.object, geometries, materials, textures, animations);
        var skeletons = this.parseSkeletons(json.skeletons, object);

        this.bindSkeletons(object, skeletons);

        if (onLoad != null) {
            var hasImages = false;
            for (uuid in images.keys()) {
                if (Std.is(images[uuid].data, HTMLImageElement)) {
                    hasImages = true;
                    break;
                }
            }

            if (!hasImages) onLoad();
        }

        return object;
    }

    private function parseAsync(json:Dynamic):Promise<Void> {
        var animations = this.parseAnimations(json.animations);
        var shapes = this.parseShapes(json.shapes);
        var geometries = this.parseGeometries(json.geometries, shapes);

        var images = this.parseImagesAsync(json.images);

        var textures = this.parseTextures(json.textures, images);
        var materials = this.parseMaterials(json.materials, textures);

        var object = this.parseObject(json.object, geometries, materials, textures, animations);
        var skeletons = this.parseSkeletons(json.skeletons, object);

        this.bindSkeletons(object, skeletons);

        return Promise.promise(object);
    }

    private function parseShapes(json:Array<Dynamic>):Map<String, Shape> {
        var shapes = new Map<String, Shape>();

        if (json != null) {
            for (i in 0...json.length) {
                var shape = new Shape().fromJSON(json[i]);
                shapes[shape.uuid] = shape;
            }
        }

        return shapes;
    }

    private function parseSkeletons(json:Array<Dynamic>, object:Object3D):Map<String, Skeleton> {
        var skeletons = new Map<String, Skeleton>();
        var bones = new Map<String, Bone>();

        object.traverse(function(child:Object3D) {
            if (child.isBone) bones[child.uuid] = child;
        });

        if (json != null) {
            for (i in 0...json.length) {
                var skeleton = new Skeleton().fromJSON(json[i], bones);
                skeletons[skeleton.uuid] = skeleton;
            }
        }

        return skeletons;
    }

    private function parseGeometries(json:Array<Dynamic>, shapes:Map<String, Shape>):Map<String, Geometry> {
        var geometries = new Map<String, Geometry>();

        if (json != null) {
            var bufferGeometryLoader = new BufferGeometryLoader();

            for (i in 0...json.length) {
                var geometry:Geometry;
                var data = json[i];

                switch (data.type) {
                    case 'BufferGeometry', 'InstancedBufferGeometry':
                        geometry = bufferGeometryLoader.parse(data);
                    default:
                        if (Geometries.exists(data.type)) {
                            geometry = Geometries.get(data.type).fromJSON(data, shapes);
                        } else {
                            trace('THREE.ObjectLoader: Unsupported geometry type "${ data.type }"');
                        }
                }

                geometry.uuid = data.uuid;

                if (data.name != null) geometry.name = data.name;
                if (data.userData != null) geometry.userData = data.userData;

                geometries[data.uuid] = geometry;
            }
        }

        return geometries;
    }

    private function parseMaterials(json:Array<Dynamic>, textures:Map<String, Texture>):Map<String, Material> {
        var cache = new Map<String, Material>();
        var materials = new Map<String, Material>();

        if (json != null) {
            var loader = new MaterialLoader();
            loader.setTextures(textures);

            for (i in 0...json.length) {
                var data = json[i];

                if (!cache.exists(data.uuid)) {
                    cache[data.uuid] = loader.parse(data);
                }

                materials[data.uuid] = cache[data.uuid];
            }
        }

        return materials;
    }

    private function parseAnimations(json:Array<Dynamic>):Map<String, AnimationClip> {
        var animations = new Map<String, AnimationClip>();

        if (json != null) {
            for (i in 0...json.length) {
                var data = json[i];
                var clip = AnimationClip.parse(data);
                animations[clip.uuid] = clip;
            }
        }

        return animations;
    }

    private function parseImages(json:Array<Dynamic>, onLoad:Void->Void):Map<String, Source> {
        var scope = this;
        var images = new Map<String, Source>();
        var loader = new ImageLoader(this.manager);
        loader.setCrossOrigin(this.crossOrigin);

        function loadImage(url:String):Source {
            scope.manager.itemStart(url);
            return loader.load(url, function() {
                scope.manager.itemEnd(url);
            }, undefined, function() {
                scope.manager.itemError(url);
                scope.manager.itemEnd(url);
            });
        }

        function deserializeImage(image:Dynamic):Source {
            if (Std.is(image, String)) {
                var url = image;
                var path = /^(\/\/)|([a-z]+:(\/\/)?)/i.test(url) ? url : scope.resourcePath + url;
                return loadImage(path);
            } else {
                if (image.data != null) {
                    return {
                        data: getTypedArray(image.type, image.data),
                        width: image.width,
                        height: image.height
                    };
                } else {
                    return null;
                }
            }
        }

        if (json != null && json.length > 0) {
            var manager = new LoadingManager(onLoad);

            for (i in 0...json.length) {
                var image = json[i];
                var url = image.url;

                if (Std.is(url, Array)) {
                    var imageArray = new Array<Source>();

                    for (j in 0...url.length) {
                        var currentUrl = url[j];
                        var deserializedImage = deserializeImage(currentUrl);

                        if (deserializedImage != null) {
                            if (Std.is(deserializedImage, HTMLImageElement)) {
                                imageArray.push(deserializedImage);
                            } else {
                                imageArray.push(new DataTexture(deserializedImage.data, deserializedImage.width, deserializedImage.height));
                            }
                        }
                    }

                    images[image.uuid] = new Source(imageArray);
                } else {
                    var deserializedImage = deserializeImage(image.url);
                    images[image.uuid] = new Source(deserializedImage);
                }
            }
        }

        return images;
    }

    private function parseImagesAsync(json:Array<Dynamic>):Promise<Map<String, Source>> {
        // todo: implement async image loading
        return Promise.promise(new Map<String, Source>());
    }
}