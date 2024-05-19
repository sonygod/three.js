package three.loaders;

import haxe.Json;
import js.html.Image;
import js.html.Uint8Array;
import three.core.Object3D;
import three.geometries.Geometry;
import three.imageLoader.ImageLoader;
import three.loaders.Loader;
import three.materials.Material;
import three.math.Color;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector3;
import three.textures.DataTexture;
import three.textures.Texture;
import three.utils.DefaultLoadingManager;

class ObjectLoader {
    public function new() {}

    async function parseImagesAsync(json:Dynamic):Map<String, Dynamic> {
        var scope = this;
        var images:Map<String, Dynamic> = new Map();
        var loader:ImageLoader = new ImageLoader(DefaultLoadingManager.INSTANCE);

        async function deserializeImage(image:Dynamic):Dynamic {
            if (Std.is(image, String)) {
                var url:String = image;
                var path:String = ~(url.indexOf("://") > -1 || url.indexOf("/") == 0) ? url : scope.resourcePath + url;
                return await loader.loadAsync(path);
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
            loader.setCrossOrigin(this.crossOrigin);

            for (i in 0...json.length) {
                var image:Dynamic = json[i];
                var url:Dynamic = image.url;

                if (Std.is(url, Array)) {
                    var imageArray:Array<Dynamic> = [];

                    for (j in 0...url.length) {
                        var currentUrl:String = url[j];
                        var deserializedImage:Dynamic = await deserializeImage(currentUrl);

                        if (deserializedImage != null) {
                            if (Std.is(deserializedImage, Image)) {
                                imageArray.push(deserializedImage);
                            } else {
                                imageArray.push(new DataTexture(deserializedImage.data, deserializedImage.width, deserializedImage.height));
                            }
                        }
                    }

                    images[image.uuid] = new Source(imageArray);
                } else {
                    var deserializedImage:Dynamic = await deserializeImage(url);
                    images[image.uuid] = new Source(deserializedImage);
                }
            }
        }

        return images;
    }

    function parseTextures(json:Array<Dynamic>, images:Map<String, Dynamic>):Map<String, Texture> {
        function parseConstant(value:Dynamic, type:Dynamic):Dynamic {
            if (Std.is(value, Float)) {
                return value;
            }

            console.warn('THREE.ObjectLoader.parseTexture: Constant should be in numeric form.', value);

            return type[value];
        }

        var textures:Map<String, Texture> = new Map();

        if (json != null) {
            for (i in 0...json.length) {
                var data:Dynamic = json[i];

                if (data.image == null) {
                    console.warn('THREE.ObjectLoader: No "image" specified for', data.uuid);
                }

                if (!images.exists(data.image)) {
                    console.warn('THREE.ObjectLoader: Undefined image', data.image);
                }

                var source:Dynamic = images[data.image];
                var image:Dynamic = source.data;

                var texture:Texture;

                if (Std.is(image, Array)) {
                    texture = new CubeTexture();

                    if (image.length == 6) {
                        texture.needsUpdate = true;
                    }
                } else {
                    if (image != null && image.data != null) {
                        texture = new DataTexture();
                    } else {
                        texture = new Texture();
                    }

                    if (image != null) {
                        texture.needsUpdate = true;
                    }
                }

                texture.source = source;

                texture.uuid = data.uuid;

                if (data.name != null) {
                    texture.name = data.name;
                }

                if (data.mapping != null) {
                    texture.mapping = parseConstant(data.mapping, TEXTURE_MAPPING);
                }

                if (data.channel != null) {
                    texture.channel = data.channel;
                }

                if (data.offset != null) {
                    texture.offset.fromArray(data.offset);
                }

                if (data.repeat != null) {
                    texture.repeat.fromArray(data.repeat);
                }

                if (data.center != null) {
                    texture.center.fromArray(data.center);
                }

                if (data.rotation != null) {
                    texture.rotation = data.rotation;
                }

                if (data.wrap != null) {
                    texture.wrapS = parseConstant(data.wrap[0], TEXTURE_WRAPPING);
                    texture.wrapT = parseConstant(data.wrap[1], TEXTURE_WRAPPING);
                }

                if (data.format != null) {
                    texture.format = data.format;
                }

                if (data.internalFormat != null) {
                    texture.internalFormat = data.internalFormat;
                }

                if (data.type != null) {
                    texture.type = data.type;
                }

                if (data.colorSpace != null) {
                    texture.colorSpace = data.colorSpace;
                }

                if (data.minFilter != null) {
                    texture.minFilter = parseConstant(data.minFilter, TEXTURE_FILTER);
                }

                if (data.magFilter != null) {
                    texture.magFilter = parseConstant(data.magFilter, TEXTURE_FILTER);
                }

                if (data.anisotropy != null) {
                    texture.anisotropy = data.anisotropy;
                }

                if (data.flipY != null) {
                    texture.flipY = data.flipY;
                }

                if (data.generateMipmaps != null) {
                    texture.generateMipmaps = data.generateMipmaps;
                }

                if (data.premultiplyAlpha != null) {
                    texture.premultiplyAlpha = data.premultiplyAlpha;
                }

                if (data.unpackAlignment != null) {
                    texture.unpackAlignment = data.unpackAlignment;
                }

                if (data.compareFunction != null) {
                    texture.compareFunction = data.compareFunction;
                }

                if (data.userData != null) {
                    texture.userData = data.userData;
                }

                textures[data.uuid] = texture;
            }
        }

        return textures;
    }

    function parseObject(data:Dynamic, geometries:Map<String, Geometry>, materials:Map<String, Material>, textures:Map<String, Texture>, animations:Map<String, Dynamic>):Object3D {
        var object:Object3D;

        function getGeometry(name:String):Geometry {
            if (!geometries.exists(name)) {
                console.warn('THREE.ObjectLoader: Undefined geometry', name);
            }

            return geometries[name];
        }

        function getMaterial(name:String):Material {
            if (name == null) {
                return null;
            }

            if (Std.is(name, Array)) {
                var array:Array<Material> = [];

                for (i in 0...name.length) {
                    var uuid:String = name[i];

                    if (!materials.exists(uuid)) {
                        console.warn('THREE.ObjectLoader: Undefined material', uuid);
                    }

                    array.push(materials[uuid]);
                }

                return array;
            }

            if (!materials.exists(name)) {
                console.warn('THREE.ObjectLoader: Undefined material', name);
            }

            return materials[name];
        }

        function getTexture(uuid:String):Texture {
            if (!textures.exists(uuid)) {
                console.warn('THREE.ObjectLoader: Undefined texture', uuid);
            }

            return textures[uuid];
        }

        switch (data.type) {
            case 'Scene':
                object = new Scene();

                if (data.background != null) {
                    if (Std.is(data.background, Float)) {
                        object.background = new Color(data.background);
                    } else {
                        object.background = getTexture(data.background);
                    }
                }

                if (data.environment != null) {
                    object.environment = getTexture(data.environment);
                }

                if (data.fog != null) {
                    if (data.fog.type == 'Fog') {
                        object.fog = new Fog(data.fog.color, data.fog.near, data.fog.far);
                    } else if (data.fog.type == 'FogExp2') {
                        object.fog = new FogExp2(data.fog.color, data.fog.density);
                    }

                    if (data.fog.name != '') {
                        object.fog.name = data.fog.name;
                    }
                }

                if (data.backgroundBlurriness != null) {
                    object.backgroundBlurriness = data.backgroundBlurriness;
                }

                if (data.backgroundIntensity != null) {
                    object.backgroundIntensity = data.backgroundIntensity;
                }

                if (data.backgroundRotation != null) {
                    object.backgroundRotation.fromArray(data.backgroundRotation);
                }

                if (data.environmentIntensity != null) {
                    object.environmentIntensity = data.environmentIntensity;
                }

                if (data.environmentRotation != null) {
                    object.environmentRotation.fromArray(data.environmentRotation);
                }

                break;
            case 'PerspectiveCamera':
                object = new PerspectiveCamera(data.fov, data.aspect, data.near, data.far);

                if (data.focus != null) {
                    object.focus = data.focus;
                }

                if (data.zoom != null) {
                    object.zoom = data.zoom;
                }

                if (data.filmGauge != null) {
                    object.filmGauge = data.filmGauge;
                }

                if (data.filmOffset != null) {
                    object.filmOffset = data.filmOffset;
                }

                if (data.view != null) {
                    object.view = Json.parse(Json.stringify(data.view));
                }

                break;
            case 'OrthographicCamera':
                object = new OrthographicCamera(data.left, data.right, data.top, data.bottom, data.near, data.far);

                if (data.zoom != null) {
                    object.zoom = data.zoom;
                }

                if (data.view != null) {
                    object.view = Json.parse(Json.stringify(data.view));
                }

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
                var geometry:Geometry = getGeometry(data.geometry);
                var material:Material = getMaterial(data.material);

                object = new SkinnedMesh(geometry, material);

                if (data.bindMode != null) {
                    object.bindMode = data.bindMode;
                }

                if (data.bindMatrix != null) {
                    object.bindMatrix.fromArray(data.bindMatrix);
                }

                if (data.skeleton != null) {
                    object.skeleton = data.skeleton;
                }

                break;
            case 'Mesh':
                geometry = getGeometry(data.geometry);
                material = getMaterial(data.material);

                object = new Mesh(geometry, material);

                break;
            case 'InstancedMesh':
                geometry = getGeometry(data.geometry);
                material = getMaterial(data.material);
                var count:Int = data.count;
                var instanceMatrix:Array<Float> = data.instanceMatrix;
                var instanceColor:Array<Float> = data.instanceColor;

                object = new InstancedMesh(geometry, material, count);
                object.instanceMatrix = new InstancedBufferAttribute(new Uint8Array(instanceMatrix), 16);

                if (instanceColor != null) {
                    object.instanceColor = new InstancedBufferAttribute(new Uint8Array(instanceColor), instanceColor.length);
                }

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
                    var box:Box3 = new Box3();
                    box.min.fromArray(bound.boxMin);
                    box.max.fromArray(bound.boxMax);

                    var sphere:Sphere = new Sphere();
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

                if (data.colorsTexture != null) {
                    object._colorsTexture = getTexture(data.colorsTexture.uuid);
                }

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

        if (data.name != null) {
            object.name = data.name;
        }

        if (data.matrix != null) {
            object.matrix.fromArray(data.matrix);

            if (data.matrixAutoUpdate != null) {
                object.matrixAutoUpdate = data.matrixAutoUpdate;
            }

            if (object.matrixAutoUpdate) {
                object.matrix.decompose(object.position, object.quaternion, object.scale);
            }
        } else {
            if (data.position != null) {
                object.position.fromArray(data.position);
            }

            if (data.rotation != null) {
                object.rotation.fromArray(data.rotation);
            }

            if (data.quaternion != null) {
                object.quaternion.fromArray(data.quaternion);
            }

            if (data.scale != null) {
                object.scale.fromArray(data.scale);
            }
        }

        if (data.up != null) {
            object.up.fromArray(data.up);
        }

        if (data.castShadow != null) {
            object.castShadow = data.castShadow;
        }

        if (data.receiveShadow != null) {
            object.receiveShadow = data.receiveShadow;
        }

        if (data.shadow != null) {
            if (data.shadow.bias != null) {
                object.shadow.bias = data.shadow.bias;
            }

            if (data.shadow.normalBias != null) {
                object.shadow.normalBias = data.shadow.normalBias;
            }

            if (data.shadow.radius != null) {
                object.shadow.radius = data.shadow.radius;
            }

            if (data.shadow.mapSize != null) {
                object.shadow.mapSize.fromArray(data.shadow.mapSize);
            }

            if (data.shadow.camera != null) {
                object.shadow.camera = this.parseObject(data.shadow.camera, geometries, materials, textures, animations);
            }
        }

        if (data.visible != null) {
            object.visible = data.visible;
        }

        if (data.frustumCulled != null) {
            object.frustumCulled = data.frustumCulled;
        }

        if (data.renderOrder != null) {
            object.renderOrder = data.renderOrder;
        }

        if (data.userData != null) {
            object.userData = data.userData;
        }

        if (data.layers != null) {
            object.layers.mask = data.layers;
        }

        if (data.children != null) {
            var children:Array<Dynamic> = data.children;

            for (i in 0...children.length) {
                object.add(this.parseObject(children[i], geometries, materials, textures, animations));
            }
        }

        if (data.animations != null) {
            var objectAnimations:Array<Dynamic> = data.animations;

            for (i in 0...objectAnimations.length) {
                var uuid:String = objectAnimations[i];

                object.animations.push(animations[uuid]);
            }
        }

        if (data.type == 'LOD') {
            if (data.autoUpdate != null) {
                object.autoUpdate = data.autoUpdate;
            }

            var levels:Array<Dynamic> = data.levels;

            for (l in 0...levels.length) {
                var level:Dynamic = levels[l];
                var child:Object3D = object.getObjectByProperty('uuid', level.object);

                if (child != null) {
                    object.addLevel(child, level.distance, level.hysteresis);
                }
            }
        }

        return object;
    }

    function bindSkeletons(object:Object3D, skeletons:Map<String, Dynamic>) {
        if (skeletons.keys().length == 0) {
            return;
        }

        object.traverse(function(child:Object3D) {
            if (child.isSkinnedMesh && child.skeleton != null) {
                var skeleton:Dynamic = skeletons[child.skeleton];

                if (skeleton == null) {
                    console.warn('THREE.ObjectLoader: No skeleton found with UUID:', child.skeleton);
                } else {
                    child.bind(skeleton, child.bindMatrix);
                }
            }
        });
    }
}

class TEXTURE_MAPPING {
    public static var UVMapping:Int;
    public static var CubeReflectionMapping:Int;
    public static var CubeRefractionMapping:Int;
    public static var EquirectangularReflectionMapping:Int;
    public static var EquirectangularRefractionMapping:Int;
    public static var CubeUVReflectionMapping:Int;
}

class TEXTURE_WRAPPING {
    public static var RepeatWrapping:Int;
    public static var ClampToEdgeWrapping:Int;
    public static var MirroredRepeatWrapping:Int;
}

class TEXTURE_FILTER {
    public static var NearestFilter:Int;
    public static var NearestMipmapNearestFilter:Int;
    public static var NearestMipmapLinearFilter:Int;
    public static var LinearFilter:Int;
    public static var LinearMipmapNearestFilter:Int;
    public static var LinearMipmapLinearFilter:Int;
}