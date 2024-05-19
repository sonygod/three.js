import haxe.Json;
import three.bufferGeometry.BufferGeometry;
import three.bufferGeometry.BufferGeometryLoader;
import three.core.Object3D;
import three.core.Points;
import three.core.PointsMaterial;
import three.core.Mesh;
import three.core.Line;
import three.core.Sprite;
import three.lights.Light;
import three.lights.PointLight;
import three.lights.SpotLight;
import three.lights.RectAreaLight;
import three.lights.DirectionalLight;
import three.materials.LineBasicMaterial;
import three.materials.PointsMaterial;
import three.materials.SpriteMaterial;
import three.math.Color;
import three.math.Matrix4;
import three.math.Vector3;
import three.loaders.BufferGeometryLoader;

class Rhino3dmLoader {
    public var url:String;
    public var libraryPath:String;
    public var libraryConfig:Dynamic;
    public var workerPool:Array<Worker>;
    public var workerLimit:Int;
    public var warnings:Array<String>;

    public function new() {
        workerPool = new Array<Worker>();
        workerLimit = 5;
        warnings = new Array<String>();
    }

    public function _createGeometry(data:Dynamic):Object3D {
        var object:Object3D = new Object3D();
        var instanceDefinitionObjects:Array<Object3D> = new Array<>();
        var instanceDefinitions:Array<Dynamic> = new Array<>();
        var instanceReferences:Array<Dynamic> = new Array<>();

        object.userData.set('layers', data.layers);
        object.userData.set('groups', data.groups);
        object.userData.set('settings', data.settings);
        object.userData.settings.set('renderSettings', data.renderSettings);
        object.userData.set('objectType', 'File3dm');
        object.userData.set('materials', null);

        object.name = url;

        var objects:Array<Dynamic> = data.objects;
        var materials:Array<Dynamic> = data.materials;

        for (i in 0...objects.length) {
            var obj:Dynamic = objects[i];
            var attributes:Dynamic = obj.attributes;

            switch (obj.objectType) {
                case 'InstanceDefinition':
                    instanceDefinitions.push(obj);
                    break;
                case 'InstanceReference':
                    instanceReferences.push(obj);
                    break;
                default:
                    var matId:Null<Int> = null;

                    switch (attributes.materialSource.name) {
                        case 'ObjectMaterialSource_MaterialFromLayer':
                            if (attributes.layerIndex >= 0) {
                                matId = data.layers[attributes.layerIndex].renderMaterialIndex;
                            }
                            break;
                        case 'ObjectMaterialSource_MaterialFromObject':
                            if (attributes.materialIndex >= 0) {
                                matId = attributes.materialIndex;
                            }
                            break;
                    }

                    var material:Material = null;

                    if (matId >= 0) {
                        var rMaterial:Dynamic = materials[matId];
                        material = _createMaterial(rMaterial, data.renderEnvironment);
                    }

                    var _object:Object3D = _createObject(obj, material);

                    if (_object == null) {
                        continue;
                    }

                    var layer:Dynamic = data.layers[attributes.layerIndex];

                    _object.visible = layer ? data.layers[attributes.layerIndex].visible : true;

                    if (attributes.isInstanceDefinitionObject) {
                        instanceDefinitionObjects.push(_object);
                    } else {
                        object.add(_object);
                    }
            }
        }

        for (i in 0...instanceDefinitions.length) {
            var iDef:Dynamic = instanceDefinitions[i];
            var objects:Array<Object3D> = new Array<>();

            for (j in 0...iDef.attributes.objectIds.length) {
                var objId:Int = iDef.attributes.objectIds[j];

                for (p in 0...instanceDefinitionObjects.length) {
                    var idoId:Int = instanceDefinitionObjects[p].userData.attributes.id;

                    if (objId == idoId) {
                        objects.push(instanceDefinitionObjects[p]);
                    }
                }
            }

            for (j in 0...instanceReferences.length) {
                var iRef:Dynamic = instanceReferences[j];

                if (iRef.geometry.parentIdefId == iDef.attributes.id) {
                    var iRefObject:Object3D = new Object3D();
                    var xf:Array<Float> = iRef.geometry.xform.array;

                    var matrix:Matrix4 = new Matrix4();
                    matrix.set(xf);

                    iRefObject.applyMatrix4(matrix);

                    for (p in 0...objects.length) {
                        iRefObject.add(objects[p].clone(true));
                    }

                    object.add(iRefObject);
                }
            }
        }

        object.userData.set('materials', materials);
        object.name = '';
        return object;
    }

    public function _createObject(obj:Dynamic, material:Material):Object3D {
        var loader:BufferGeometryLoader = new BufferGeometryLoader();

        var attributes:Dynamic = obj.attributes;

        var geometry:BufferGeometry;
        var material:Material;
        var _color:Dynamic;
        var color:Color;

        switch (obj.objectType) {
            case 'Point', 'PointSet':
                geometry = loader.parse(obj.geometry);

                if (geometry.attributes.hasOwnProperty('color')) {
                    material = new PointsMaterial({ vertexColors: true, sizeAttenuation: false, size: 2 });
                } else {
                    _color = attributes.drawColor;
                    color = new Color(_color.r / 255.0, _color.g / 255.0, _color.b / 255.0);
                    material = new PointsMaterial({ color: color, sizeAttenuation: false, size: 2 });
                }

                material = _compareMaterials(material);

                var points:Points = new Points(geometry, material);
                points.userData.set('attributes', attributes);
                points.userData.set('objectType', obj.objectType);

                if (attributes.name) {
                    points.name = attributes.name;
                }

                return points;

            case 'Mesh', 'Extrusion', 'SubD', 'Brep':
                if (obj.geometry == null) return null;

                geometry = loader.parse(obj.geometry);

                if (material == null) {
                    material = _createMaterial();
                }

                if (geometry.attributes.hasOwnProperty('color')) {
                    material.vertexColors = true;
                }

                material = _compareMaterials(material);

                var mesh:Mesh = new Mesh(geometry, material);
                mesh.castShadow = attributes.castsShadows;
                mesh.receiveShadow = attributes.receivesShadows;
                mesh.userData.set('attributes', attributes);
                mesh.userData.set('objectType', obj.objectType);

                if (attributes.name) {
                    mesh.name = attributes.name;
                }

                return mesh;

            case 'Curve':
                geometry = loader.parse(obj.geometry);

                _color = attributes.drawColor;
                color = new Color(_color.r / 255.0, _color.g / 255.0, _color.b / 255.0);

                material = new LineBasicMaterial({ color: color });
                material = _compareMaterials(material);

                var lines:Line = new Line(geometry, material);
                lines.userData.set('attributes', attributes);
                lines.userData.set('objectType', obj.objectType);

                if (attributes.name) {
                    lines.name = attributes.name;
                }

                return lines;

            case 'TextDot':
                geometry = obj.geometry;

                var ctx:js.html.CanvasRenderingContext2D = js.Browser.document.createElement('canvas').getContext('2d');
                var font:String = '${geometry.fontHeight}px ${geometry.fontFace}';
                ctx.font = font;
                var width:Float = ctx.measureText(geometry.text).width + 10;
                var height:Float = geometry.fontHeight + 10;

                var r:Float = js.Browser.window.devicePixelRatio;

                ctx.canvas.width = width * r;
                ctx.canvas.height = height * r;
                ctx.canvas.style.width = width + 'px';
                ctx.canvas.style.height = height + 'px';
                ctx.setTransform(r, 0, 0, r, 0, 0);

                ctx.font = font;
                ctx.textBaseline = 'middle';
                ctx.textAlign = 'center';
                color = attributes.drawColor;
                ctx.fillStyle = 'rgba(${color.r},${color.g},${color.b},${color.a})';
                ctx.fillRect(0, 0, width, height);
                ctx.fillStyle = 'white';
                ctx.fillText(geometry.text, width / 2, height / 2);

                var texture:Texture = new CanvasTexture(ctx.canvas);
                texture.minFilter = LinearFilter;
                texture.wrapS = ClampToEdgeWrapping;
                texture.wrapT = ClampToEdgeWrapping;

                material = new SpriteMaterial({ map: texture, depthTest: false });
                var sprite:Sprite = new Sprite(material);
                sprite.position.set(geometry.point[0], geometry.point[1], geometry.point[2]);
                sprite.scale.set(width / 10, height / 10, 1.0);

                sprite.userData.set('attributes', attributes);
                sprite.userData.set('objectType', obj.objectType);

                if (attributes.name) {
                    sprite.name = attributes.name;
                }

                return sprite;

            case 'Light':
                geometry = obj.geometry;

                var light:Light;

                switch (geometry.lightStyle.name) {
                    case 'LightStyle_WorldPoint':
                        light = new PointLight();
                        light.castShadow = attributes.castsShadows;
                        light.position.set(geometry.location[0], geometry.location[1], geometry.location[2]);
                        light.shadow.normalBias = 0.1;

                        break;

                    case 'LightStyle_WorldSpot':
                        light = new SpotLight();
                        light.castShadow = attributes.castsShadows;
                        light.position.set(geometry.location[0], geometry.location[1], geometry.location[2]);
                        light.target.position.set(geometry.direction[0], geometry.direction[1], geometry.direction[2]);
                        light.angle = geometry.spotAngleRadians;
                        light.shadow.normalBias = 0.1;

                        break;

                    case 'LightStyle_WorldRectangular':
                        light = new RectAreaLight();
                        var width:Float = Math.abs(geometry.width[2]);
                        var height:Float = Math.abs(geometry.length[0]);
                        light.position.set(geometry.location[0] - (height / 2), geometry.location[1], geometry.location[2] - (width / 2));
                        light.height = height;
                        light.width = width;
                        light.lookAt(geometry.direction[0], geometry.direction[1], geometry.direction[2]);

                        break;

                    case 'LightStyle_WorldDirectional':
                        light = new DirectionalLight();
                        light.castShadow = attributes.castsShadows;
                        light.position.set(geometry.location[0], geometry.location[1], geometry.location[2]);
                        light.target.position.set(geometry.direction[0], geometry.direction[1], geometry.direction[2]);
                        light.shadow.normalBias = 0.1;

                        break;

                    case 'LightStyle_WorldLinear':
                        // no conversion exists, warning has already been printed to the console
                        break;

                    default:
                        break;
                }

                if (light) {
                    light.intensity = geometry.intensity;
                    _color = geometry.diffuse;
                    color = new Color(_color.r / 255.0, _color.g / 255.0, _color.b / 255.0);
                    light.color = color;
                    light.userData.set('attributes', attributes);
                    light.userData.set('objectType', obj.objectType);
                }

                return light;
        }

        return null;
    }

    public function _initLibrary():Promise<Dynamic> {
        if (!libraryPending) {
            libraryPending = new Promise((resolve, reject) -> {
                var jsLoader:FileLoader = new FileLoader(this.manager);
                jsLoader.setPath(libraryPath);
                var jsContent:Promise<String> = jsLoader.load('rhino3dm.js', resolve, undefined, reject);

                var binaryLoader:FileLoader = new FileLoader(this.manager);
                binaryLoader.setPath(libraryPath);
                binaryLoader.setResponseType('arraybuffer');
                var binaryContent:Promise<ArrayBuffer> = binaryLoader.load('rhino3dm.wasm', resolve, undefined, reject);

                this.libraryPending = Promise.all([jsContent, binaryContent]).then((results:Array<Dynamic>) -> {
                    var jsContent:String = results[0];
                    var binaryContent:ArrayBuffer = results[1];

                    this.libraryConfig.wasmBinary = binaryContent;

                    var fn:String = Rhino3dmWorker.toString();

                    var body:Array<String> = [
                        '/* rhino3dm.js */',
                        jsContent,
                        '/* worker */',
                        fn.substring(fn.indexOf('{') + 1, fn.lastIndexOf('}'))
                    ].join('\n');

                    this.workerSourceURL = js.Browser.URL.createObjectURL(new js.html.Blob([body]));

                    resolve(this.workerSourceURL);
                });
            });
        }

        return libraryPending;
    }

    public function _getWorker(taskCost:Float):Promise<Worker> {
        return _initLibrary().then(() -> {
            if (workerPool.length < workerLimit) {
                var worker:Worker = new Worker(workerSourceURL);

                worker._callbacks = {};
                worker._taskCosts = {};
                worker._taskLoad = 0;

                worker.postMessage({
                    type: 'init',
                    libraryConfig: libraryConfig
                });

                worker.onmessage = (e:Dynamic) -> {
                    var message:Dynamic = e.data;

                    switch (message.type) {
                        case 'warning':
                            warnings.push(message.data);
                            console.warn(message.data);
                            break;
                        case 'decode':
                            worker._callbacks[message.id].resolve(message);
                            break;
                        case 'error':
                            worker._callbacks[message.id].reject(message);
                            break;
                        default:
                            console.error('THREE.Rhino3dmLoader: Unexpected message, "' + message.type + '"');
                    }
                };

                workerPool.push(worker);
            } else {
                workerPool.sort((a:Worker, b:Worker) -> {
                    return a._taskLoad > b._taskLoad ? -1 : 1;
                });
            }

            var worker:Worker = workerPool[workerPool.length - 1];

            worker._taskLoad += taskCost;

            return worker;
        });
    }
}