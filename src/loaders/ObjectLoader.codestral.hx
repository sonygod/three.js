package three.js.loaders;

import three.js.constants.TextureMapping;
import three.js.constants.TextureWrapping;
import three.js.constants.TextureFilter;
import three.js.core.InstancedBufferAttribute;
import three.js.math.Color;
import three.js.math.Vector3;
import three.js.math.Quaternion;
import three.js.math.Box3;
import three.js.math.Sphere;
import three.js.core.Object3D;
import three.js.objects.Group;
import three.js.objects.InstancedMesh;
import three.js.objects.BatchedMesh;
import three.js.objects.Sprite;
import three.js.objects.Points;
import three.js.objects.Line;
import three.js.objects.LineLoop;
import three.js.objects.LineSegments;
import three.js.objects.LOD;
import three.js.objects.Mesh;
import three.js.objects.SkinnedMesh;
import three.js.objects.Bone;
import three.js.objects.Skeleton;
import three.js.extras.core.Shape;
import three.js.scenes.Fog;
import three.js.scenes.FogExp2;
import three.js.lights.HemisphereLight;
import three.js.lights.SpotLight;
import three.js.lights.PointLight;
import three.js.lights.DirectionalLight;
import three.js.lights.AmbientLight;
import three.js.lights.RectAreaLight;
import three.js.lights.LightProbe;
import three.js.cameras.OrthographicCamera;
import three.js.cameras.PerspectiveCamera;
import three.js.scenes.Scene;
import three.js.textures.CubeTexture;
import three.js.textures.Texture;
import three.js.textures.Source;
import three.js.textures.DataTexture;
import three.js.loaders.ImageLoader;
import three.js.loaders.LoadingManager;
import three.js.animation.AnimationClip;
import three.js.loaders.MaterialLoader;
import three.js.loaders.LoaderUtils;
import three.js.loaders.BufferGeometryLoader;
import three.js.loaders.Loader;
import three.js.loaders.FileLoader;
import three.js.geometries.Geometries;
import three.js.utils.Utils;

class ObjectLoader extends Loader {
    public function new(manager?: LoadingManager) {
        super(manager);
    }

    public function load(url: String, onLoad: Null<(object: Object3D) -> Void>, onProgress: Null<(event: ProgressEvent) -> Void>, onError: Null<(event: ErrorEvent) -> Void>): Void {
        var scope = this;
        var path = (this.path === '') ? LoaderUtils.extractUrlBase(url) : this.path;
        this.resourcePath = this.resourcePath || path;

        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(text: String) {
            var json = null;

            try {
                json = JSON.parse(text);
            } catch (error) {
                if (onError !== null) onError(error);
                trace('THREE:ObjectLoader: Can\'t parse ' + url + '.', error.message);
                return;
            }

            var metadata = json.metadata;

            if (metadata === null || metadata.type === null || metadata.type.toLowerCase() === 'geometry') {
                if (onError !== null) onError(new Error('THREE.ObjectLoader: Can\'t load ' + url));
                trace('THREE.ObjectLoader: Can\'t load ' + url);
                return;
            }

            scope.parse(json, onLoad);
        }, onProgress, onError);
    }

    public async function loadAsync(url: String, onProgress: Null<(event: ProgressEvent) -> Void>): Promise<Object3D> {
        var scope = this;
        var path = (this.path === '') ? LoaderUtils.extractUrlBase(url) : this.path;
        this.resourcePath = this.resourcePath || path;

        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);

        var text = await loader.loadAsync(url, onProgress);

        var json = JSON.parse(text);

        var metadata = json.metadata;

        if (metadata === null || metadata.type === null || metadata.type.toLowerCase() === 'geometry') {
            throw new Error('THREE.ObjectLoader: Can\'t load ' + url);
        }

        return await scope.parseAsync(json);
    }

    public function parse(json: Dynamic, onLoad: Null<(object: Object3D) -> Void>): Object3D {
        var animations = this.parseAnimations(json.animations);
        var shapes = this.parseShapes(json.shapes);
        var geometries = this.parseGeometries(json.geometries, shapes);

        var images = this.parseImages(json.images, function() {
            if (onLoad !== null) onLoad(object);
        });

        var textures = this.parseTextures(json.textures, images);
        var materials = this.parseMaterials(json.materials, textures);

        var object = this.parseObject(json.object, geometries, materials, textures, animations);
        var skeletons = this.parseSkeletons(json.skeletons, object);

        this.bindSkeletons(object, skeletons);

        if (onLoad !== null) {
            var hasImages = false;

            for (uuid in images) {
                if (Std.is(images[uuid].data, HTMLImageElement)) {
                    hasImages = true;
                    break;
                }
            }

            if (hasImages === false) onLoad(object);
        }

        return object;
    }

    public async function parseAsync(json: Dynamic): Promise<Object3D> {
        var animations = this.parseAnimations(json.animations);
        var shapes = this.parseShapes(json.shapes);
        var geometries = this.parseGeometries(json.geometries, shapes);

        var images = await this.parseImagesAsync(json.images);

        var textures = this.parseTextures(json.textures, images);
        var materials = this.parseMaterials(json.materials, textures);

        var object = this.parseObject(json.object, geometries, materials, textures, animations);
        var skeletons = this.parseSkeletons(json.skeletons, object);

        this.bindSkeletons(object, skeletons);

        return object;
    }

    private function parseShapes(json: Dynamic): Dynamic {
        var shapes = {};

        if (json !== null) {
            for (var i = 0; i < json.length; i++) {
                var shape = new Shape().fromJSON(json[i]);
                shapes[shape.uuid] = shape;
            }
        }

        return shapes;
    }

    private function parseSkeletons(json: Dynamic, object: Object3D): Dynamic {
        var skeletons = {};
        var bones = {};

        object.traverse(function(child: Object3D) {
            if (child is Bone) bones[child.uuid] = child;
        });

        if (json !== null) {
            for (var i = 0; i < json.length; i++) {
                var skeleton = new Skeleton().fromJSON(json[i], bones);
                skeletons[skeleton.uuid] = skeleton;
            }
        }

        return skeletons;
    }

    private function parseGeometries(json: Dynamic, shapes: Dynamic): Dynamic {
        var geometries = {};

        if (json !== null) {
            var bufferGeometryLoader = new BufferGeometryLoader();

            for (var i = 0; i < json.length; i++) {
                var geometry = null;
                var data = json[i];

                switch (data.type) {
                    case 'BufferGeometry':
                    case 'InstancedBufferGeometry':
                        geometry = bufferGeometryLoader.parse(data);
                        break;
                    default:
                        if (Reflect.hasField(Type, data.type)) {
                            geometry = Type.createInstance(Type.resolveClass(data.type), []).fromJSON(data, shapes);
                        } else {
                            trace('THREE.ObjectLoader: Unsupported geometry type "' + data.type + '"');
                        }
                }

                if (geometry !== null) {
                    geometry.uuid = data.uuid;

                    if (data.name !== null) geometry.name = data.name;
                    if (data.userData !== null) geometry.userData = data.userData;

                    geometries[data.uuid] = geometry;
                }
            }
        }

        return geometries;
    }

    private function parseMaterials(json: Dynamic, textures: Dynamic): Dynamic {
        var cache = {};
        var materials = {};

        if (json !== null) {
            var loader = new MaterialLoader();
            loader.setTextures(textures);

            for (var i = 0; i < json.length; i++) {
                var data = json[i];

                if (cache[data.uuid] === null) {
                    cache[data.uuid] = loader.parse(data);
                }

                materials[data.uuid] = cache[data.uuid];
            }
        }

        return materials;
    }

    private function parseAnimations(json: Dynamic): Dynamic {
        var animations = {};

        if (json !== null) {
            for (var i = 0; i < json.length; i++) {
                var data = json[i];
                var clip = AnimationClip.parse(data);
                animations[clip.uuid] = clip;
            }
        }

        return animations;
    }

    private function parseImages(json: Dynamic, onLoad: Null<() -> Void>): Dynamic {
        var scope = this;
        var images = {};

        var loader: ImageLoader;

        function loadImage(url: String): HTMLImageElement {
            scope.manager.itemStart(url);

            return loader.load(url, function() {
                scope.manager.itemEnd(url);
            }, null, function() {
                scope.manager.itemError(url);
                scope.manager.itemEnd(url);
            });
        }

        function deserializeImage(image: Dynamic): Dynamic {
            if (Std.is(image, String)) {
                var url = image;
                var path = /^(\/\/)|([a-z]+:(\/\/)?)/i.match(url) ? url : scope.resourcePath + url;
                return loadImage(path);
            } else {
                if (image.data !== null) {
                    return {
                        data: Utils.getTypedArray(image.type, image.data),
                        width: image.width,
                        height: image.height
                    };
                } else {
                    return null;
                }
            }
        }

        if (json !== null && json.length > 0) {
            var manager = new LoadingManager(onLoad);

            loader = new ImageLoader(manager);
            loader.setCrossOrigin(this.crossOrigin);

            for (var i = 0; i < json.length; i++) {
                var image = json[i];
                var url = image.url;

                if (Std.is(url, Array<Dynamic>)) {
                    var imageArray = [];

                    for (var j = 0; j < url.length; j++) {
                        var currentUrl = url[j];
                        var deserializedImage = deserializeImage(currentUrl);

                        if (deserializedImage !== null) {
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

    private async function parseImagesAsync(json: Dynamic): Promise<Dynamic> {
        var scope = this;
        var images = {};

        var loader: ImageLoader;

        async function deserializeImage(image: Dynamic): Promise<Dynamic> {
            if (Std.is(image, String)) {
                var url = image;
                var path = /^(\/\/)|([a-z]+:(\/\/)?)/i.match(url) ? url : scope.resourcePath + url;
                return await loader.loadAsync(path);
            } else {
                if (image.data !== null) {
                    return {
                        data: Utils.getTypedArray(image.type, image.data),
                        width: image.width,
                        height: image.height
                    };
                } else {
                    return null;
                }
            }
        }

        if (json !== null && json.length > 0) {
            loader = new ImageLoader(this.manager);
            loader.setCrossOrigin(this.crossOrigin);

            for (var i = 0; i < json.length; i++) {
                var image = json[i];
                var url = image.url;

                if (Std.is(url, Array<Dynamic>)) {
                    var imageArray = [];

                    for (var j = 0; j < url.length; j++) {
                        var currentUrl = url[j];
                        var deserializedImage = await deserializeImage(currentUrl);

                        if (deserializedImage !== null) {
                            if (Std.is(deserializedImage, HTMLImageElement)) {
                                imageArray.push(deserializedImage);
                            } else {
                                imageArray.push(new DataTexture(deserializedImage.data, deserializedImage.width, deserializedImage.height));
                            }
                        }
                    }

                    images[image.uuid] = new Source(imageArray);
                } else {
                    var deserializedImage = await deserializeImage(image.url);
                    images[image.uuid] = new Source(deserializedImage);
                }
            }
        }

        return images;
    }

    private function parseTextures(json: Dynamic, images: Dynamic): Dynamic {
        function parseConstant(value: Dynamic, type: Dynamic): Dynamic {
            if (Std.is(value, Int)) return value;

            trace('THREE.ObjectLoader.parseTexture: Constant should be in numeric form.', value);
            return Reflect.field(type, value);
        }

        var textures = {};

        if (json !== null) {
            for (var i = 0; i < json.length; i++) {
                var data = json[i];

                if (data.image === null) {
                    trace('THREE.ObjectLoader: No "image" specified for', data.uuid);
                }

                if (images[data.image] === null) {
                    trace('THREE.ObjectLoader: Undefined image', data.image);
                }

                var source = images[data.image];
                var image = source.data;

                var texture = null;

                if (Std.is(image, Array<Dynamic>)) {
                    texture = new CubeTexture();

                    if (image.length === 6) texture.needsUpdate = true;
                } else {
                    if (image !== null && image.data !== null) {
                        texture = new DataTexture();
                    } else {
                        texture = new Texture();
                    }

                    if (image !== null) texture.needsUpdate = true;
                }

                texture.source = source;
                texture.uuid = data.uuid;

                if (data.name !== null) texture.name = data.name;

                if (data.mapping !== null) texture.mapping = parseConstant(data.mapping, TextureMapping);
                if (data.channel !== null) texture.channel = data.channel;

                if (data.offset !== null) texture.offset.fromArray(data.offset);
                if (data.repeat !== null) texture.repeat.fromArray(data.repeat);
                if (data.center !== null) texture.center.fromArray(data.center);
                if (data.rotation !== null) texture.rotation = data.rotation;

                if (data.wrap !== null) {
                    texture.wrapS = parseConstant(data.wrap[0], TextureWrapping);
                    texture.wrapT = parseConstant(data.wrap[1], TextureWrapping);
                }

                if (data.format !== null) texture.format = data.format;
                if (data.internalFormat !== null) texture.internalFormat = data.internalFormat;
                if (data.type !== null) texture.type = data.type;
                if (data.colorSpace !== null) texture.colorSpace = data.colorSpace;

                if (data.minFilter !== null) texture.minFilter = parseConstant(data.minFilter, TextureFilter);
                if (data.magFilter !== null) texture.magFilter = parseConstant(data.magFilter, TextureFilter);
                if (data.anisotropy !== null) texture.anisotropy = data.anisotropy;

                if (data.flipY !== null) texture.flipY = data.flipY;

                if (data.generateMipmaps !== null) texture.generateMipmaps = data.generateMipmaps;
                if (data.premultiplyAlpha !== null) texture.premultiplyAlpha = data.premultiplyAlpha;
                if (data.unpackAlignment !== null) texture.unpackAlignment = data.unpackAlignment;
                if (data.compareFunction !== null) texture.compareFunction = data.compareFunction;

                if (data.userData !== null) texture.userData = data.userData;

                textures[data.uuid] = texture;
            }
        }

        return textures;
    }

    private function parseObject(data: Dynamic, geometries: Dynamic, materials: Dynamic, textures: Dynamic, animations: Dynamic): Object3D {
        var object: Object3D;

        function getGeometry(name: String): Object3D {
            if (geometries[name] === null) {
                trace('THREE.ObjectLoader: Undefined geometry', name);
            }

            return geometries[name];
        }

        function getMaterial(name: Dynamic): Dynamic {
            if (name === null) return null;

            if (Std.is(name, Array<String>)) {
                var array = [];

                for (var i = 0; i < name.length; i++) {
                    var uuid = name[i];

                    if (materials[uuid] === null) {
                        trace('THREE.ObjectLoader: Undefined material', uuid);
                    }

                    array.push(materials[uuid]);
                }

                return array;
            }

            if (materials[name] === null) {
                trace('THREE.ObjectLoader: Undefined material', name);
            }

            return materials[name];
        }

        function getTexture(uuid: String): Texture {
            if (textures[uuid] === null) {
                trace('THREE.ObjectLoader: Undefined texture', uuid);
            }

            return textures[uuid];
        }

        var geometry: Object3D;
        var material: Dynamic;

        switch (data.type) {
            case 'Scene':
                object = new Scene();

                if (data.background !== null) {
                    if (Std.is(data.background, Int)) {
                        object.background = new Color(data.background);
                    } else {
                        object.background = getTexture(data.background);
                    }
                }

                if (data.environment !== null) {
                    object.environment = getTexture(data.environment);
                }

                if (data.fog !== null) {
                    if (data.fog.type === 'Fog') {
                        object.fog = new Fog(data.fog.color, data.fog.near, data.fog.far);
                    } else if (data.fog.type === 'FogExp2') {
                        object.fog = new FogExp2(data.fog.color, data.fog.density);
                    }

                    if (data.fog.name !== '') {
                        object.fog.name = data.fog.name;
                    }
                }

                if (data.backgroundBlurriness !== null) object.backgroundBlurriness = data.backgroundBlurriness;
                if (data.backgroundIntensity !== null) object.backgroundIntensity = data.backgroundIntensity;
                if (data.backgroundRotation !== null) object.backgroundRotation.fromArray(data.backgroundRotation);

                if (data.environmentIntensity !== null) object.environmentIntensity = data.environmentIntensity;
                if (data.environmentRotation !== null) object.environmentRotation.fromArray(data.environmentRotation);

                break;

            case 'PerspectiveCamera':
                object = new PerspectiveCamera(data.fov, data.aspect, data.near, data.far);

                if (data.focus !== null) object.focus = data.focus;
                if (data.zoom !== null) object.zoom = data.zoom;
                if (data.filmGauge !== null) object.filmGauge = data.filmGauge;
                if (data.filmOffset !== null) object.filmOffset = data.filmOffset;
                if (data.view !== null) object.view = data.view.copy();

                break;

            case 'OrthographicCamera':
                object = new OrthographicCamera(data.left, data.right, data.top, data.bottom, data.near, data.far);

                if (data.zoom !== null) object.zoom = data.zoom;
                if (data.view !== null) object.view = data.view.copy();

                break;

            case 'AmbientLight':
                object = new AmbientLight(data.color, data.intensity);
                break;

            case 'DirectionalLight':
                object = new DirectionalLight(data.color, data.intensity);
                break;

            case 'PointLight':
                object = new PointLight(data.color, data.intensity, data.distance, data.decay);
                break;

            case 'RectAreaLight':
                object = new RectAreaLight(data.color, data.intensity, data.width, data.height);
                break;

            case 'SpotLight':
                object = new SpotLight(data.color, data.intensity, data.distance, data.angle, data.penumbra, data.decay);
                break;

            case 'HemisphereLight':
                object = new HemisphereLight(data.color, data.groundColor, data.intensity);
                break;

            case 'LightProbe':
                object = new LightProbe().fromJSON(data);
                break;

            case 'SkinnedMesh':
                geometry = getGeometry(data.geometry);
                material = getMaterial(data.material);

                object = new SkinnedMesh(geometry, material);

                if (data.bindMode !== null) object.bindMode = data.bindMode;
                if (data.bindMatrix !== null) object.bindMatrix.fromArray(data.bindMatrix);
                if (data.skeleton !== null) object.skeleton = data.skeleton;

                break;

            case 'Mesh':
                geometry = getGeometry(data.geometry);
                material = getMaterial(data.material);

                object = new Mesh(geometry, material);

                break;

            case 'InstancedMesh':
                geometry = getGeometry(data.geometry);
                material = getMaterial(data.material);
                var count = data.count;
                var instanceMatrix = data.instanceMatrix;
                var instanceColor = data.instanceColor;

                object = new InstancedMesh(geometry, material, count);
                object.instanceMatrix = new InstancedBufferAttribute(new Float32Array(instanceMatrix.array), 16);
                if (instanceColor !== null) object.instanceColor = new InstancedBufferAttribute(new Float32Array(instanceColor.array), instanceColor.itemSize);

                break;

            case 'BatchedMesh':
                geometry = getGeometry(data.geometry);
                material = getMaterial(data.material);

                object = new BatchedMesh(data.maxGeometryCount, data.maxVertexCount, data.maxIndexCount, material);
                object.geometry = geometry;
                object.perObjectFrustumCulled = data.perObjectFrustumCulled;
                object.sortObjects = data.sortObjects;

                object._drawRanges = data.drawRanges;
                object._reservedRanges = data.reservedRanges;

                object._visibility = data.visibility;
                object._active = data.active;
                object._bounds = data.bounds.map(function(bound) {
                    var box = new Box3();
                    box.min.fromArray(bound.boxMin);
                    box.max.fromArray(bound.boxMax);

                    var sphere = new Sphere();
                    sphere.radius = bound.sphereRadius;
                    sphere.center.fromArray(bound.sphereCenter);

                    return {
                        boxInitialized: bound.boxInitialized,
                        box: box,
                        sphereInitialized: bound.sphereInitialized,
                        sphere: sphere
                    };
                });

                object._maxGeometryCount = data.maxGeometryCount;
                object._maxVertexCount = data.maxVertexCount;
                object._maxIndexCount = data.maxIndexCount;

                object._geometryInitialized = data.geometryInitialized;
                object._geometryCount = data.geometryCount;

                object._matricesTexture = getTexture(data.matricesTexture.uuid);
                if (data.colorsTexture !== null) object._colorsTexture = getTexture(data.colorsTexture.uuid);

                break;

            case 'LOD':
                object = new LOD();
                break;

            case 'Line':
                object = new Line(getGeometry(data.geometry), getMaterial(data.material));
                break;

            case 'LineLoop':
                object = new LineLoop(getGeometry(data.geometry), getMaterial(data.material));
                break;

            case 'LineSegments':
                object = new LineSegments(getGeometry(data.geometry), getMaterial(data.material));
                break;

            case 'PointCloud':
            case 'Points':
                object = new Points(getGeometry(data.geometry), getMaterial(data.material));
                break;

            case 'Sprite':
                object = new Sprite(getMaterial(data.material));
                break;

            case 'Group':
                object = new Group();
                break;

            case 'Bone':
                object = new Bone();
                break;

            default:
                object = new Object3D();
        }

        object.uuid = data.uuid;

        if (data.name !== null) object.name = data.name;

        if (data.matrix !== null) {
            object.matrix.fromArray(data.matrix);

            if (data.matrixAutoUpdate !== null) object.matrixAutoUpdate = data.matrixAutoUpdate;
            if (object.matrixAutoUpdate) object.matrix.decompose(object.position, object.quaternion, object.scale);
        } else {
            if (data.position !== null) object.position.fromArray(data.position);
            if (data.rotation !== null) object.rotation.fromArray(data.rotation);
            if (data.quaternion !== null) object.quaternion.fromArray(data.quaternion);
            if (data.scale !== null) object.scale.fromArray(data.scale);
        }

        if (data.up !== null) object.up.fromArray(data.up);

        if (data.castShadow !== null) object.castShadow = data.castShadow;
        if (data.receiveShadow !== null) object.receiveShadow = data.receiveShadow;

        if (data.shadow !== null) {
            if (data.shadow.bias !== null) object.shadow.bias = data.shadow.bias;
            if (data.shadow.normalBias !== null) object.shadow.normalBias = data.shadow.normalBias;
            if (data.shadow.radius !== null) object.shadow.radius = data.shadow.radius;
            if (data.shadow.mapSize !== null) object.shadow.mapSize.fromArray(data.shadow.mapSize);
            if (data.shadow.camera !== null) object.shadow.camera = this.parseObject(data.shadow.camera);
        }

        if (data.visible !== null) object.visible = data.visible;
        if (data.frustumCulled !== null) object.frustumCulled = data.frustumCulled;
        if (data.renderOrder !== null) object.renderOrder = data.renderOrder;
        if (data.userData !== null) object.userData = data.userData;
        if (data.layers !== null) object.layers.mask = data.layers;

        if (data.children !== null) {
            var children = data.children;

            for (var i = 0; i < children.length; i++) {
                object.add(this.parseObject(children[i], geometries, materials, textures, animations));
            }
        }

        if (data.animations !== null) {
            var objectAnimations = data.animations;

            for (var i = 0; i < objectAnimations.length; i++) {
                var uuid = objectAnimations[i];
                object.animations.push(animations[uuid]);
            }
        }

        if (data.type === 'LOD') {
            if (data.autoUpdate !== null) object.autoUpdate = data.autoUpdate;

            var levels = data.levels;

            for (var l = 0; l < levels.length; l++) {
                var level = levels[l];
                var child = object.getObjectByProperty('uuid', level.object);

                if (child !== null) {
                    object.addLevel(child, level.distance, level.hysteresis);
                }
            }
        }

        return object;
    }

    private function bindSkeletons(object: Object3D, skeletons: Dynamic): Void {
        if (Reflect.fields(skeletons).length === 0) return;

        object.traverse(function(child: Object3D) {
            if (child is SkinnedMesh && child.skeleton !== null) {
                var skeleton = skeletons[child.skeleton];

                if (skeleton === null) {
                    trace('THREE.ObjectLoader: No skeleton found with UUID:', child.skeleton);
                } else {
                    child.bind(skeleton, child.bindMatrix);
                }
            }
        });
    }
}