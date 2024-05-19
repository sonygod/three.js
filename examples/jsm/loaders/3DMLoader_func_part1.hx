package three.js.examples.jsm.loaders;

import three.js.BufferGeometryLoader;
import three.js.CanvasTexture;
import three.js.ClampToEdgeWrapping;
import three.js.Color;
import three.js.DirectionalLight;
import three.js.DoubleSide;
import three.js.FileLoader;
import three.js.LinearFilter;
import three.js.Line;
import three.js.LineBasicMaterial;
import three.js.Loader;
import three.js.Matrix4;
import three.js.Mesh;
import three.js.MeshPhysicalMaterial;
import three.js.MeshStandardMaterial;
import three.js.Object3D;
import three.js.PointLight;
import three.js.Points;
import three.js.PointsMaterial;
import three.js.RectAreaLight;
import three.js.RepeatWrapping;
import three.js.SpotLight;
import three.js.Sprite;
import three.js.SpriteMaterial;
import three.js.TextureLoader;

import loaders.EXRLoader;

class Rhino3dmLoader extends Loader {
    private var libraryPath:String;
    private var libraryPending:Null<Dynamic>;
    private var libraryBinary:Null<Dynamic>;
    private var libraryConfig:Dynamic;

    private var url:String;

    private var workerLimit:Int;
    private var workerPool:Array<Dynamic>;
    private var workerNextTaskID:Int;
    private var workerSourceURL:String;
    private var workerConfig:Dynamic;

    private var materials:Array<Dynamic>;
    private var warnings:Array<Dynamic>;

    public function new(manager:Loader) {
        super(manager);

        libraryPath = '';
        libraryPending = null;
        libraryBinary = null;
        libraryConfig = {};

        url = '';

        workerLimit = 4;
        workerPool = [];
        workerNextTaskID = 1;
        workerSourceURL = '';
        workerConfig = {};

        materials = [];
        warnings = [];
    }

    public function setLibraryPath(path:String):Rhino3dmLoader {
        libraryPath = path;
        return this;
    }

    public function setWorkerLimit(workerLimit:Int):Rhino3dmLoader {
        this.workerLimit = workerLimit;
        return this;
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var loader:FileLoader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);

        this.url = url;

        loader.load(url, function(buffer:Dynamic) {
            if (_taskCache.exists(buffer)) {
                var cachedTask:Dynamic = _taskCache.get(buffer);
                cachedTask.promise.then(onLoad).catchError(onError);
            } else {
                decodeObjects(buffer, url).then(function(result:Dynamic) {
                    result.userData.warnings = warnings;
                    onLoad(result);
                }).catchError(onError);
            }
        }, onProgress, onError);
    }

    public function debug():Void {
        trace('Task load: ' + workerPool.map(function(worker:Dynamic) return worker._taskLoad));
    }

    private function decodeObjects(buffer:Dynamic, url:String):Promise<Dynamic> {
        var worker:Dynamic;
        var taskID:Int;

        var taskCost:Int = buffer.byteLength;

        var objectPending:Promise<Dynamic> = _getWorker(taskCost).then(function(_worker:Dynamic) {
            worker = _worker;
            taskID = workerNextTaskID++;
            return new Promise(function(resolve:Dynamic->Void, reject:Dynamic->Void) {
                worker._callbacks[taskID] = { resolve: resolve, reject: reject };
                worker.postMessage({ type: 'decode', id: taskID, buffer }, [buffer]);
            });
        }).then(function(message:Dynamic) {
            return _createGeometry(message.data);
        }).catchError(function(e:Dynamic) {
            throw e;
        });

        objectPending.catchError(function() {
            true;
        }).then(function() {
            if (worker != null && taskID != null) {
                _releaseTask(worker, taskID);
            }
        });

        _taskCache.set(buffer, {
            url: url,
            promise: objectPending
        });

        return objectPending;
    }

    public function parse(data:Dynamic, onLoad:Dynamic->Void, onError:Dynamic->Void):Void {
        decodeObjects(data, '').then(function(result:Dynamic) {
            result.userData.warnings = warnings;
            onLoad(result);
        }).catchError(onError);
    }

    private function _compareMaterials(material:Dynamic):Dynamic {
        var mat:Dynamic = {};
        mat.name = material.name;
        mat.color = {};
        mat.color.r = material.color.r;
        mat.color.g = material.color.g;
        mat.color.b = material.color.b;
        mat.type = material.type;
        mat.vertexColors = material.vertexColors;

        var json:String = Json.stringify(mat);

        for (i in 0...materials.length) {
            var m:Dynamic = materials[i];
            var _mat:Dynamic = {};
            _mat.name = m.name;
            _mat.color = {};
            _mat.color.r = m.color.r;
            _mat.color.g = m.color.g;
            _mat.color.b = m.color.b;
            _mat.type = m.type;
            _mat.vertexColors = m.vertexColors;

            if (Json.stringify(_mat) == json) {
                return m;
            }
        }

        materials.push(material);
        return material;
    }

    private function _createMaterial(material:Dynamic, renderEnvironment:Dynamic):MeshPhysicalMaterial {
        if (material == null) {
            return new MeshStandardMaterial({
                color: new Color(1, 1, 1),
                metalness: 0.8,
                name: Loader.DEFAULT_MATERIAL_NAME,
                side: DoubleSide
            });
        }

        var mat:MeshPhysicalMaterial = new MeshPhysicalMaterial({
            color: new Color(material.diffuseColor.r / 255.0, material.diffuseColor.g / 255.0, material.diffuseColor.b / 255.0),
            emissive: new Color(material.emissionColor.r, material.emissionColor.g, material.emissionColor.b),
            flatShading: material.disableLighting,
            ior: material.indexOfRefraction,
            name: material.name,
            reflectivity: material.reflectivity,
            opacity: 1.0 - material.transparency,
            side: DoubleSide,
            specularColor: material.specularColor,
            transparent: material.transparency > 0 ? true : false
        });

        mat.userData.id = material.id;

        if (material.pbrSupported) {
            var pbr:Dynamic = material.pbr;

            mat.anisotropy = pbr.anisotropic;
            mat.anisotropyRotation = pbr.anisotropicRotation;
            mat.color = new Color(pbr.baseColor.r, pbr.baseColor.g, pbr.baseColor.b);
            mat.clearcoat = pbr.clearcoat;
            mat.clearcoatRoughness = pbr.clearcoatRoughness;
            mat.metalness = pbr.metallic;
            mat.transmission = 1 - pbr.opacity;
            mat.roughness = pbr.roughness;
            mat.sheen = pbr.sheen;
            mat.specularIntensity = pbr.specular;
            mat.thickness = pbr.subsurface;
        }

        if (material.pbrSupported && material.pbr.opacity === 0 && material.transparency === 1) {
            mat.opacity = 0.2;
            mat.transmission = 1.00;
        }

        var textureLoader:TextureLoader = new TextureLoader();

        for (i in 0...material.textures.length) {
            var texture:Dynamic = material.textures[i];

            if (texture.image != null) {
                var map:Texture = textureLoader.load(texture.image);

                switch (texture.type) {
                    case 'Bump':
                        mat.bumpMap = map;
                        break;

                    case 'Diffuse':
                        mat.map = map;
                        break;

                    case 'Emap':
                        mat.envMap = map;
                        break;

                    case 'Opacity':
                        mat.transmissionMap = map;
                        break;

                    case 'Transparency':
                        mat.alphaMap = map;
                        mat.transparent = true;
                        break;

                    case 'PBR_Alpha':
                        mat.alphaMap = map;
                        mat.transparent = true;
                        break;

                    case 'PBR_AmbientOcclusion':
                        mat.aoMap = map;
                        break;

                    case 'PBR_Anisotropic':
                        mat.anisotropyMap = map;
                        break;

                    case 'PBR_BaseColor':
                        mat.map = map;
                        break;

                    case 'PBR_Clearcoat':
                        mat.clearcoatMap = map;
                        break;

                    case 'PBR_ClearcoatBump':
                        mat.clearcoatNormalMap = map;
                        break;

                    case 'PBR_ClearcoatRoughness':
                        mat.clearcoatRoughnessMap = map;
                        break;

                    case 'PBR_Displacement':
                        mat.displacementMap = map;
                        break;

                    case 'PBR_Emission':
                        mat.emissiveMap = map;
                        break;

                    case 'PBR_Metallic':
                        mat.metalnessMap = map;
                        break;

                    case 'PBR_Roughness':
                        mat.roughnessMap = map;
                        break;

                    case 'PBR_Sheen':
                        mat.sheenColorMap = map;
                        break;

                    case 'PBR_Specular':
                        mat.specularColorMap = map;
                        break;

                    case 'PBR_Subsurface':
                        mat.thicknessMap = map;
                        break;

                    default:
                        warnings.push({
                            message: 'THREE.3DMLoader: No conversion exists for 3dm ' + texture.type + '.',
                            type: 'no conversion'
                        });
                        break;
                }

                map.wrapS = texture.wrapU === 0 ? RepeatWrapping : ClampToEdgeWrapping;
                map.wrapT = texture.wrapV === 0 ? RepeatWrapping : ClampToEdgeWrapping;

                if (texture.repeat) {
                    map.repeat.set(texture.repeat[0], texture.repeat[1]);
                }
            }
        }

        if (renderEnvironment != null) {
            new EXRLoader().load(renderEnvironment.image, function(texture:Texture) {
                texture.mapping = EquirectangularReflectionMapping;
                mat.envMap = texture;
            });
        }

        return mat;
    }
}