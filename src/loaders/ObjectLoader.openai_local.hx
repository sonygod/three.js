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

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope = this;
        var path = (this.path == '') ? LoaderUtils.extractUrlBase(url) : this.path;
        this.resourcePath = this.resourcePath != null ? this.resourcePath : path;

        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(text:String) {
            var json = try Json.parse(text) catch (e:Dynamic) {
                if (onError != null) onError(e);
                trace('THREE:ObjectLoader: Can\'t parse ' + url + '.', e.message);
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

    public function loadAsync(url:String, onProgress:Dynamic->Void):Future<Dynamic> {
        return FileLoader.loadAsync(url, onProgress).then(function(text:String):Future<Dynamic> {
            var json = Json.parse(text);
            var metadata = json.metadata;
            if (metadata == null || metadata.type == null || metadata.type.toLowerCase() == 'geometry') {
                throw new Error('THREE.ObjectLoader: Can\'t load ' + url);
            }
            return scope.parseAsync(json);
        });
    }

    public function parse(json:Dynamic, onLoad:Dynamic->Void):Dynamic {
        var animations = this.parseAnimations(json.animations);
        var shapes = this.parseShapes(json.shapes);
        var geometries = this.parseGeometries(json.geometries, shapes);

        var images = this.parseImages(json.images, function() {
            if (onLoad != null) onLoad(object);
        });

        var textures = this.parseTextures(json.textures, images);
        var materials = this.parseMaterials(json.materials, textures);

        var object = this.parseObject(json.object, geometries, materials, textures, animations);
        var skeletons = this.parseSkeletons(json.skeletons, object);

        this.bindSkeletons(object, skeletons);

        if (onLoad != null) {
            var hasImages = false;
            for (uuid in images) {
                if (Std.is(images[uuid].data, js.html.ImageElement)) {
                    hasImages = true;
                    break;
                }
            }
            if (!hasImages) onLoad(object);
        }

        return object;
    }

    public function parseAsync(json:Dynamic):Future<Dynamic> {
        var animations = this.parseAnimations(json.animations);
        var shapes = this.parseShapes(json.shapes);
        var geometries = this.parseGeometries(json.geometries, shapes);

        return this.parseImagesAsync(json.images).then(function(images:Dynamic) {
            var textures = this.parseTextures(json.textures, images);
            var materials = this.parseMaterials(json.materials, textures);
            var object = this.parseObject(json.object, geometries, materials, textures, animations);
            var skeletons = this.parseSkeletons(json.skeletons, object);

            this.bindSkeletons(object, skeletons);

            return object;
        });
    }

    public function parseShapes(json:Array<Dynamic>):Map<String,Shape> {
        var shapes = new Map<String,Shape>();
        if (json != null) {
            for (i in 0...json.length) {
                var shape = new Shape().fromJSON(json[i]);
                shapes.set(shape.uuid, shape);
            }
        }
        return shapes;
    }

    public function parseSkeletons(json:Array<Dynamic>, object:Object3D):Map<String,Skeleton> {
        var skeletons = new Map<String,Skeleton>();
        var bones = new Map<String,Bone>();

        object.traverse(function(child:Object3D) {
            if (child.isBone) bones.set(child.uuid, cast(child, Bone));
        });

        if (json != null) {
            for (i in 0...json.length) {
                var skeleton = new Skeleton().fromJSON(json[i], bones);
                skeletons.set(skeleton.uuid, skeleton);
            }
        }

        return skeletons;
    }

    public function parseGeometries(json:Array<Dynamic>, shapes:Map<String,Shape>):Map<String,Dynamic> {
        var geometries = new Map<String,Dynamic>();
        if (json != null) {
            var bufferGeometryLoader = new BufferGeometryLoader();
            for (i in 0...json.length) {
                var data = json[i];
                var geometry;
                switch (data.type) {
                    case 'BufferGeometry':
                    case 'InstancedBufferGeometry':
                        geometry = bufferGeometryLoader.parse(data);
                        break;
                    default:
                        if (Reflect.hasField(Geometries, data.type)) {
                            geometry = Reflect.field(Geometries, data.type).fromJSON(data, shapes);
                        } else {
                            trace('THREE.ObjectLoader: Unsupported geometry type "' + data.type + '"');
                        }
                }
                geometry.uuid = data.uuid;
                if (data.name != null) geometry.name = data.name;
                if (data.userData != null) geometry.userData = data.userData;
                geometries.set(data.uuid, geometry);
            }
        }
        return geometries;
    }

    public function parseMaterials(json:Array<Dynamic>, textures:Map<String,Texture>):Map<String,Dynamic> {
        var cache = new Map<String,Dynamic>();
        var materials = new Map<String,Dynamic>();
        if (json != null) {
            var loader = new MaterialLoader();
            loader.setTextures(textures);
            for (i in 0...json.length) {
                var data = json[i];
                if (!cache.exists(data.uuid)) {
                    cache.set(data.uuid, loader.parse(data));
                }
                materials.set(data.uuid, cache.get(data.uuid));
            }
        }
        return materials;
    }

    public function parseAnimations(json:Array<Dynamic>):Map<String,AnimationClip> {
        var animations = new Map<String,AnimationClip>();
        if (json != null) {
            for (i in 0...json.length) {
                var data = json[i];
                var clip = AnimationClip.parse(data);
                animations.set(clip.uuid, clip);
            }
        }
        return animations;
    }

    public function parseImages(json:Array<Dynamic>, onLoad:Void->Void):Map<String,Source> {
        var scope = this;
        var images = new Map<String,Source>();
        var loader;

        function loadImage(url:String):Void {
            scope.manager.itemStart(url);
            loader.load(url, function() {
                scope.manager.itemEnd(url);
            }, null, function() {
                scope.manager.itemError(url);
                scope.manager.itemEnd(url);
            });
        }

        function deserializeImage(image:Dynamic):Dynamic {
            if (Std.is(image, String)) {
                var url = cast(image, String);
                var path = ~/^(\/\/)|([a-z]+:(\/\/)?)/i.match(url) ? url : scope.resourcePath + url;
                loadImage(path);
            } else {
                if (image.data != null) {
                    return {
                        data: image.data,
                        width: image.width,
                        height: image.height
                    };
                }
                if (image.uuid != null) {
                    images.set(image.uuid, {
                        url: scope.resourcePath + image.url,
                        userData: image.userData
                    });
                    loadImage(image.url);
                }
            }
        }

        if (json != null && json.length > 0) {
            loader = new ImageLoader(this.manager);
            loader.setCrossOrigin(this.crossOrigin);
            loader.setPath(this.resourcePath);
            loader.setRequestHeader(this.requestHeader);
            loader.setWithCredentials(this.withCredentials);

            for (i in 0...json.length) {
                var image = json[i];
                var url = (this.path != '') ? LoaderUtils.extractUrlBase(image.url) : '';
                if (url != '' && !this.path.endsWith('/')) url += '/';

                images.set(image.uuid, {
                    data: deserializeImage(image),
                    url: image.url,
                    userData: image.userData
                });
            }
        }

        onLoad();

        return images;
    }

    public function parseImagesAsync(json:Array<Dynamic>):Future<Map<String,Source>> {
        var scope = this;
        var images = new Map<String,Source>();
        var loader;

        function loadImageAsync(url:String):Future<Dynamic> {
            return loader.loadAsync(url).handle(function(r:Result<Dynamic,Dynamic>) {
                switch (r) {
                    case Success(result):
                        return result;
                    case Failure(error):
                        return Future.sync(error);
                }
            });
        }

        function deserializeImageAsync(image:Dynamic):Future<Dynamic> {
            if (Std.is(image, String)) {
                var url = cast(image, String);
                var path = ~/^(\/\/)|([a-z]+:(\/\/)?)/i.match(url) ? url : scope.resourcePath + url;
                return loadImageAsync(path);
            } else {
                if (image.data != null) {
                    return Future.sync({
                        data: image.data,
                        width: image.width,
                        height: image.height
                    });
                }
                if (image.uuid != null) {
                    images.set(image.uuid, {
                        url: scope.resourcePath + image.url,
                        userData: image.userData
                    });
                    return loadImageAsync(image.url);
                }
                return Future.sync(null);
            }
        }

        if (json != null && json.length > 0) {
            loader = new ImageLoader(this.manager);
            loader.setCrossOrigin(this.crossOrigin);
            loader.setPath(this.resourcePath);
            loader.setRequestHeader(this.requestHeader);
            loader.setWithCredentials(this.withCredentials);

            var futures = json.map(function(image) {
                var url = (scope.path != '') ? LoaderUtils.extractUrlBase(image.url) : '';
                if (url != '' && !scope.path.endsWith('/')) url += '/';

                return deserializeImageAsync(image).handle(function(r:Result<Dynamic,Dynamic>) {
                    switch (r) {
                        case Success(result):
                            images.set(image.uuid, {
                                data: result,
                                url: image.url,
                                userData: image.userData
                            });
                        case Failure(error):
                            return Future.sync(error);
                    }
                });
            });

            return Future.sequence(futures).map(function(_) return images);
        }

        return Future.sync(images);
    }

    public function parseObject(data:Dynamic, geometries:Map<String,Dynamic>, materials:Map<String,Dynamic>, textures:Map<String,Dynamic>, animations:Map<String,Dynamic>):Object3D {
        var object = new Object3D();
        var geometriesMap = geometries;
        var materialsMap = materials;
        var texturesMap = textures;
        var animationsMap = animations;

        function getObject(uuid:String):Dynamic {
            if (uuid != null) {
                var obj = geometriesMap.get(uuid);
                if (obj == null) obj = materialsMap.get(uuid);
                if (obj == null) obj = texturesMap.get(uuid);
                if (obj == null) obj = animationsMap.get(uuid);
                return obj;
            }
            return null;
        }

        if (data.type != null) {
            if (Reflect.hasField(three.objects, data.type)) {
                object = Reflect.field(three.objects, data.type);
            } else {
                object = Reflect.field(three.objects, 'Mesh');
            }
        }

        object.uuid = data.uuid;
        if (data.name != null) object.name = data.name;
        if (data.userData != null) object.userData = data.userData;

        if (data.matrix != null) {
            object.matrix.fromArray(data.matrix);
            object.matrix.decompose(object.position, object.quaternion, object.scale);
        } else {
            if (data.position != null) object.position.fromArray(data.position);
            if (data.rotation != null) object.rotation.fromArray(data.rotation);
            if (data.quaternion != null) object.quaternion.fromArray(data.quaternion);
            if (data.scale != null) object.scale.fromArray(data.scale);
        }

        if (data.castShadow != null) object.castShadow = data.castShadow;
        if (data.receiveShadow != null) object.receiveShadow = data.receiveShadow;

        if (data.visible != null) object.visible = data.visible;
        if (data.frustumCulled != null) object.frustumCulled = data.frustumCulled;
        if (data.renderOrder != null) object.renderOrder = data.renderOrder;

        if (data.layers != null) object.layers.mask = data.layers;

        if (data.children != null) {
            for (i in 0...data.children.length) {
                object.add(this.parseObject(data.children[i], geometries, materials, textures, animations));
            }
        }

        if (data.geometry != null) {
            var geometry = getObject(data.geometry);
            if (geometry != null) object.geometry = geometry;
        }

        if (data.material != null) {
            if (Std.is(data.material, Array)) {
                var materialsArray = [];
                for (i in 0...data.material.length) {
                    var material = getObject(data.material[i]);
                    if (material != null) materialsArray.push(material);
                }
                object.material = materialsArray;
            } else {
                var material = getObject(data.material);
                if (material != null) object.material = material;
            }
        }

        if (data.animations != null) {
            object.animations = [];
            for (i in 0...data.animations.length) {
                var clip = getObject(data.animations[i]);
                if (clip != null) object.animations.push(clip);
            }
        }

        if (data.script != null) {
            object.script = data.script;
        }

        return object;
    }

    public function bindSkeletons(object:Object3D, skeletons:Map<String,Skeleton>):Void {
        object.traverse(function(child:Object3D) {
            if (child.isSkinnedMesh && Reflect.hasField(child, 'skeleton') && Reflect.hasField(child.skeleton, 'uuid')) {
                if (skeletons.exists(child.skeleton.uuid)) {
                    var skeleton = skeletons.get(child.skeleton.uuid);
                    child.bind(skeleton, child.bindMatrix);
                } else {
                    trace('THREE.ObjectLoader: Skeleton not found for UUID ' + child.skeleton.uuid);
                }
            }
        });
    }
}