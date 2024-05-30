import haxe.zip.Reader;
import js.Browser;
import js.html.Blob;
import js.html.File;
import js.html.FileReader;
import js.html.URL;
import js.html.XMLHttpRequest;
import js.lib.FileError;
import js.node.Fs;
import js.node.Http;
import js.node.buffer.Buffer;
import js.node.buffer.SlowBuffer;
import js.node.fs.Stats;
import js.node.http.IncomingMessage;
import js.node.net.Socket;
import js.sys.ArrayBuffer;
import js.sys.DataInput;
import js.sys.Reflect;
import openfl.Lib;
import sys.FileSystem;
import sys.io.FileInput;
import sys.io.FileOutput;
import sys.net.HttpStatus;
import sys.net.Http;
import sys.net.HttpHeader;
import sys.net.HttpService;
import sys.net.HttpVersion;
import sys.net.HttpStatus;
import sys.net.HttpHeader;
import sys.net.HttpService;
import sys.net.HttpVersion;
import three.addons.loaders.ColladaLoader;
import three.addons.loaders.GLTFLoader;
import three.addons.loaders.KMZLoader;
import three.addons.loaders.LDrawLoader;
import three.addons.loaders.MD2Loader;
import three.addons.loaders.MTLLoader;
import three.addons.loaders.OBJLoader;
import three.addons.loaders.PCDLoader;
import three.addons.loaders.PLYLoader;
import three.addons.loaders.STLLoader;
import three.addons.loaders.SVGLoader;
import three.addons.loaders.TGALoader;
import three.addons.loaders.USDZLoader;
import three.addons.loaders.VOXLoader;
import three.addons.loaders.VRMLLoader;
import three.addons.loaders.VTKLoader;
import three.addons.loaders.XYZLoader;
import three.addons.libs.draco.DRACOLoader;
import three.addons.libs.fflate.unzipSync;
import three.addons.libs.meshopt_decoder.MeshoptDecoder;
import three.examples.jsm.libs.basis.KTX2Loader;
import three.examples.jsm.libs.draco.gltf.DecoderPath;
import three.examples.jsm.libs.draco.DRACOLoader;
import three.examples.jsm.libs.rhino3dm.Rhino3dmLoader;
import three.extras.core.Face3;
import three.extras.core.Geometry;
import three.extras.core.Object3D;
import three.extras.core.Vector2;
import three.extras.curves.Curve;
import three.extras.curves.Path;
import three.extras.curves.Shape;
import three.extras.curves.shapes.ShapeUtils;
import three.extras.objects.Group;
import three.extras.objects.ImmediateRenderObject;
import three.extras.objects.Line;
import three.extras.objects.LineLoop;
import three.extras.objects.LineSegments;
import three.extras.objects.Points;
import three.extras.objects.Ribbon;
import three.extras.objects.ShapeGeometry;
import three.extras.objects.type.Group;
import three.extras.objects.util.ImmediateRenderObjectType;
import three.loaders.BufferGeometryLoader;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.loaders.ObjectLoader;
import three.loaders.FileLoader;
import three.materials.LineBasicMaterial;
import three.materials.LineDashedMaterial;
import three.materials.Material;
import three.materials.MeshBasicMaterial;
import three.materials.MeshDepthMaterial;
import three.materials.MeshDistanceMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.MeshMatcapMaterial;
import three.materials.MeshNormalMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.MeshPhysicalMaterial;
import three.materials.MeshStandardMaterial;
import three.materials.MeshToonMaterial;
import three.materials.PointsMaterial;
import three.materials.RawShaderMaterial;
import three.materials.ShaderMaterial;
import three.math.Color;
import three.math.Euler;
import three.math.Matrix3;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Sphere;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.objects.Bone;
import three.objects.Group;
import three.objects.Line;
import three.objects.LineLoop;
import three.objects.LineSegments;
import three.objects.Loda;
import three.objects.Mesh;
import three.renderers.webgl.WebGLBufferRenderer;
import three.renderers.webgl.WebGLClippingRenderer;
import three.renderers.webgl.WebGLCubeRenderTarget;
import three.renderers.webgl.WebGLDeferredRenderer;
import three.renderers.webgl.WebGLGeometries;
import three.renderers.webgl.WebGLIndexedBufferRenderer;
import three.renderers.webgl.WebGLMorphtargetsRenderer;
import three.renderers.webgl.WebGLObject;
import three.renderers.webgl.WebGLProgram;
import three.renderers.webgl.WebGLProperties;
import three.renderers.webgl.WebGLRenderLists;
import three.renderers.webgl.WebGLRenderTarget;
import three.renderers.webgl.WebGLRenderTargetCube;
import three.renderers.webgl.WebGLShadowMap;
import three.renderers.webgl.WebGLShader;
import three.renderers.webgl.WebGLState;
import three.renderers.webgl.WebGLTextures;
import three.renderers.webgl.WebGLUniforms;
import three.renderers.webgl.WebGLUtils;

class Loader {
    public var texturePath:String;
    private var _scope:Loader;

    public function new(editor:Dynamic) {
        _scope = this;
    }

    public function loadItemList(items:Dynamic) {
        LoaderUtils.getFilesFromItemList(items, function(files, filesMap) {
            loadFiles(files, filesMap);
        });
    }

    public function loadFiles(files:Array<File>, filesMap:Map<String, File>) {
        if (files.length > 0) {
            filesMap = filesMap ?? LoaderUtils.createFilesMap(files);
            var manager = new three.LoadingManager();
            manager.setURLModifier(function(url) {
                url = url.replace(/^(\.\/?)/, ''); // remove './'
                var file = filesMap[url];
                if (file) {
                    trace('Loading $url');
                    return URL.createObjectURL(file);
                }
                return url;
            });
            manager.addHandler(/\.tga$/i, new TGALoader());
            for (i in 0...files.length) {
                loadFile(files[i], manager);
            }
        }
    }

    public function loadFile(file:File, manager:three.LoadingManager) {
        var filename = file.name;
        var extension = filename.split('.').pop().toLowerCase();
        var reader = new FileReader();
        reader.addEventListener('progress', function(event) {
            var size = '(' + editor.utils.formatNumber(Std.int(event.loaded / 1000)) + ' KB)';
            var progress = Std.string(Std.int(event.loaded / event.total * 100)) + '%';
            trace('Loading $filename $size $progress');
        });
        switch (extension) {
            case '3dm':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var Rhino3dmLoader = cast three.addons.loaders.Rhino3dmLoader(
                        untyped __js__(await import('three/addons/loaders/3DMLoader.js'))
                    );
                    var loader = new Rhino3dmLoader();
                    loader.setLibraryPath('../examples/jsm/libs/rhino3dm/');
                    loader.parse(contents, function(object) {
                        object.name = filename;
                        editor.execute(new AddObjectCommand(editor, object));
                    }, function(error) {
                        trace(error);
                    });
                });
                reader.readAsArrayBuffer(file);
                break;
            case '3ds':
                reader.addEventListener('load', function(event) {
                    var TDSLoader = cast three.addons.loaders.TDSLoader(
                        untyped __js__(await import('three/addons/loaders/TDSLoader.js'))
                    );
                    var loader = new TDSLoader();
                    var object = loader.parse(event.target.result);
                    editor.execute(new AddObjectCommand(editor, object));
                });
                reader.readAsArrayBuffer(file);
                break;
            case '3mf':
                reader.addEventListener('load', function(event) {
                    var ThreeMFLoader = cast three.addons.loaders.ThreeMFLoader(
                        untyped __js__(await import('three/addons/loaders/3MFLoader.js'))
                    );
                    var loader = new ThreeMFLoader();
                    var object = loader.parse(event.target.result);
                    editor.execute(new AddObjectCommand(editor, object));
                });
                reader.readAsArrayBuffer(file);
                break;
            case 'amf':
                reader.addEventListener('load', function(event) {
                    var AMFLoader = cast three.addons.loaders.AMFLoader(
                        untyped __js__(await import('three/addons/loaders/AMFLoader.js'))
                    );
                    var loader = new AMFLoader();
                    var amfobject = loader.parse(event.target.result);
                    editor.execute(new AddObjectCommand(editor, amfobject));
                });
                reader.readAsArrayBuffer(file);
                break;
            case 'dae':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var ColladaLoader = cast three.addons.loaders.ColladaLoader(
                        untyped __js__(await import('three/addons/loaders/ColladaLoader.js'))
                    );
                    var loader = new ColladaLoader(manager);
                    var collada = loader.parse(contents);
                    collada.scene.name = filename;
                    editor.execute(new AddObjectCommand(editor, collada.scene));
                });
                reader.readAsText(file);
                break;
            case 'drc':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var DRACOLoader = cast three.addons.loaders.DRACOLoader(
                        untyped __js__(await import('three/addons/loaders/DRACOLoader.js'))
                    );
                    var loader = new DRACOLoader();
                    loader.setDecoderPath('../examples/jsm/libs/draco/');
                    loader.parse(contents, function(geometry) {
                        var object:Object3D;
                        if (geometry.index != null) {
                            var material = new three.MeshStandardMaterial();
                            object = new three.Mesh(geometry, material);
                            object.name = filename;
                        } else {
                            var material = new three.PointsMaterial({ size: 0.01 });
                            material.vertexColors = geometry.hasAttribute('color');
                            object = new three.Points(geometry, material);
                            object.name = filename;
                        }
                        loader.dispose();
                        editor.execute(new AddObjectCommand(editor, object));
                    });
                });
                reader.readAsArrayBuffer(file);
                break;
            case 'fbx':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var FBXLoader = cast three.addons.loaders.FBXLoader(
                        untyped __js__(await import('three/addons/loaders/FBXLoader.js'))
                    );
                    var loader = new FBXLoader(manager);
                    var object = loader.parse(contents);
                    editor.execute(new AddObjectCommand(editor, object));
                });
                reader.readAsArrayBuffer(file);
                break;
            case 'glb':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var loader = await createGLTFLoader();
                    loader.parse(contents, '', function(result) {
                        var scene = result.scene;
                        scene.name = filename;
                        scene.animations.push(...result.animations);
                        editor.execute(new AddObjectCommand(editor, scene));
                        loader.dracoLoader.dispose();
                        loader.ktx2Loader.dispose();
                    });
                });
                reader.readAsArrayBuffer(file);
                break;
            case 'gltf':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var loader = await createGLTFLoader(manager);
                    loader.parse(contents, '', function(result) {
                        var scene = result.scene;
                        scene.name = filename;
                        scene.animations.push(...result.animations);
                        editor.execute(new AddObjectCommand(editor, scene));
                        loader.dracoLoader.dispose();
                        loader.ktx2Loader.dispose();
                    });
                });
                reader.readAsArrayBuffer(file);
                break;
            case 'js':
            case 'json':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    // 2.0
                    if (contents.indexOf('postMessage') != -1) {
                        var blob = new Blob([contents], { type: 'text/javascript' });
                        var url = URL.createObjectURL(blob);
                        var worker = new Worker(url);
                        worker.onmessage = function(event) {
                            event.data.metadata = { version: 2 };
                            handleJSON(event.data);
                        };
                        worker.postMessage(Date.now());
                        return;
                    }
                    // >= 3.0
                    var data:Dynamic;
                    try {
                        data = untyped __js__('JSON').parse(contents);
                    } catch (_) {
                        alert(_);
                        return;
                    }
                    handleJSON(data);
                });
                reader.readAsText(file);
                break;
            case 'kmz':
                reader.addEventListener('load', function(event) {
                    var KMZLoader = cast three.addons.loaders.KMZLoader(
                        untyped __js__(await import('three/addons/loaders/KMZLoader.js'))
                    );
                    var loader = new KMZLoader();
                    var collada = loader.parse(event.target.result);
                    collada.scene.name = filename;
                    editor.execute(new AddObjectCommand(editor, collada.scene));
                });
                reader.readAsArrayBuffer(file);
                break;
            case 'ldr':
            case 'mpd':
                reader.addEventListener('load', function(event) {
                    var LDrawLoader = cast three.addons.loaders.LDrawLoader(
                        untyped __js__(await import('three/addons/loaders/LDrawLoader.js'))
                    );
                    var loader = new LDrawLoader();
                    loader.setPath('../../examples/models/ldraw/officialLibrary/');
                    loader.parse(event.target.result, function(group) {
                        group.name = filename;
                        // Convert from LDraw coordinates: rotate 180 degrees around OX
                        group.rotation.x = Math.PI;
                        editor.execute(new AddObjectCommand(editor, group));
                    });
                });
                reader.readAsText(file);
                break;
            case 'md2':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var MD2Loader = cast three.addons.loaders.MD2Loader(
                        untyped __js__(await import('three/addons/loaders/MD2Loader.js'))
                    );
                    var geometry = new MD2Loader().parse(contents);
                    var material = new three.MeshStandardMaterial();
                    var mesh = new three.Mesh(geometry, material);
                    mesh.mixer = new three.AnimationMixer(mesh);
                    mesh.name = filename;
                    mesh.animations.push(...geometry.animations);
                    editor.execute(new AddObjectCommand(editor, mesh));
                });
                reader.readAsArrayBuffer(file);
                break;
            case 'obj':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var OBJLoader = cast three.addons.loaders.OBJLoader(
                        untyped __js__(await import('three/addons/loaders/OBJLoader.js'))
                    );
                    var object = new OBJLoader().parse(contents);
                    object.name = filename;
                    editor.execute(new AddObjectCommand(editor, object));
                });
                reader.readAsText(file);
                break;
            case 'pcd':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var PCDLoader = cast three.addons.loaders.PCDLoader(
                        untyped __js__(await import('three/addons/loaders/PCDLoader.js'))
                    );
                    var points = new PCDLoader().parse(contents);
                    points.name = filename;
                    editor.execute(new AddObjectCommand(editor, points));
                });
                reader.readAsArrayBuffer(file);
                break;
            case 'ply':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var PLYLoader = cast three.addons.loaders.PLYLoader(
                        untyped __js__(await import('three/addons/loaders/PLYLoader.js'))
                    );
                    var geometry = new PLYLoader().parse(contents);
                    var object:Object3D;
                    if
                    if (geometry.index != null) {
                        var material = new three.MeshStandardMaterial();
                        object = new three.Mesh(geometry, material);
                        object.name = filename;
                    } else {
                        var material = new three.PointsMaterial({ size: 0.01 });
                        material.vertexColors = geometry.hasAttribute('color');
                        object = new three.Points(geometry, material);
                        object.name = filename;
                    }
                    editor.execute(new AddObjectCommand(editor, object));
                });
                reader.readAsArrayBuffer(file);
                break;
            case 'stl':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var STLLoader = cast three.addons.loaders.STLLoader(
                        untyped __js__(await import('three/addons/loaders/STLLoader.js'))
                    );
                    var geometry = new STLLoader().parse(contents);
                    var material = new three.MeshStandardMaterial();
                    var mesh = new three.Mesh(geometry, material);
                    mesh.name = filename;
                    editor.execute(new AddObjectCommand(editor, mesh));
                });
                if (reader.readAsBinaryString != null) {
                    reader.readAsBinaryString(file);
                } else {
                    reader.readAsArrayBuffer(file);
                }
                break;
            case 'svg':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var SVGLoader = cast three.addons.loaders.SVGLoader(
                        untyped __js__(await import('three/addons/loaders/SVGLoader.js'))
                    );
                    var loader = new SVGLoader();
                    var paths = loader.parse(contents).paths;
                    //
                    var group = new three.Group();
                    group.name = filename;
                    group.scale.multiplyScalar(0.1);
                    group.scale.y *= -1;
                    for (i in 0...paths.length) {
                        var path = paths[i];
                        var material = new three.MeshBasicMaterial({
                            color: path.color,
                            depthWrite: false
                        });
                        var shapes = SVGLoader.createShapes(path);
                        for (j in 0...shapes.length) {
                            var shape = shapes[j];
                            var geometry = new three.ShapeGeometry(shape);
                            var mesh = new three.Mesh(geometry, material);
                            group.add(mesh);
                        }
                    }
                    editor.execute(new AddObjectCommand(editor, group));
                });
                reader.readAsText(file);
                break;
            case 'usdz':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var USDZLoader = cast three.addons.loaders.USDZLoader(
                        untyped __js__(await import('three/addons/loaders/USDZLoader.js'))
                    );
                    var group = new USDZLoader().parse(contents);
                    group.name = filename;
                    editor.execute(new AddObjectCommand(editor, group));
                });
                reader.readAsArrayBuffer(file);
                break;
            case 'vox':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var VOXLoader = cast three.addons.loaders.VOXLoader(
                        untyped __js__(await import('three/addons/loaders/VOXLoader.js'))
                    );
                    var VOXMesh = cast three.extras.objects.type.Group(
                        untyped __js__(await import('three/addons/loaders/VOXLoader.js'))
                    );
                    var chunks = new VOXLoader().parse(contents);
                    var group = new three.Group();
                    group.name = filename;
                    for (i in 0...chunks.length) {
                        var chunk = chunks[i];
                        var mesh = new VOXMesh(chunk);
                        group.add(mesh);
                    }
                    editor.execute(new AddObjectCommand(editor, group));
                });
                reader.readAsArrayBuffer(file);
                break;
            case 'vtk':
            case 'vtp':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var VTKLoader = cast three.addons.loaders.VTKLoader(
                        untyped __js__(await import('three/addons/loaders/VTKLoader.js'))
                    );
                    var geometry = new VTKLoader().parse(contents);
                    var material = new three.MeshStandardMaterial();
                    var mesh = new three.Mesh(geometry, material);
                    mesh.name = filename;
                    editor.execute(new AddObjectCommand(editor, mesh));
                });
                reader.readAsArrayBuffer(file);
                break;
            case 'wrl':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var VRMLLoader = cast three.addons.loaders.VRMLLoader(
                        untyped __js__(await import('three/addons/loaders/VRMLLoader.js'))
                    );
                    var result = new VRMLLoader().parse(contents);
                    editor.execute(new AddObjectCommand(editor, result));
                });
                reader.readAsText(file);
                break;
            case 'xyz':
                reader.addEventListener('load', function(event) {
                    var contents = event.target.result;
                    var XYZLoader = cast three.addons.loaders.XYZLoader(
                        untyped __js__(await import('three/addons/loaders/XYZLoader.js'))
                    );
                    var geometry = new XYZLoader().parse(contents);
                    var material = new three.PointsMaterial();
                    material.vertexColors = geometry.hasAttribute('color');
                    var points = new three.Points(geometry, material);
                    points.name = filename;
                    editor.execute(new AddObjectCommand(editor, points));
                });
                reader.readAsText(file);
                break;
            case 'zip':
                reader.addEventListener('load', function(event) {
                    handleZIP(event.target.result);
                });
                reader.readAsArrayBuffer(file);
                break;
            default:
                trace('Unsupported file format ($extension).');
                break;
        }
    }

    function handleJSON(data:Dynamic) {
        if (data.metadata == null) { // 2.0
            data.metadata = { type: 'Geometry' };
        }
        if (data.metadata.type == null) { // 3.0
            data.metadata.type = 'Geometry';
        }
        if (data.metadata.formatVersion != null) {
            data.metadata.version = data.metadata.formatVersion;
        }
        switch (data.metadata.type.toLowerCase()) {
            case 'buffergeometry':
                var loader = new three.BufferGeometryLoader();
                var result = loader.parse(data);
                var mesh = new three.Mesh(result);
                editor.execute(new AddObjectCommand(editor, mesh));
                break;
            case 'geometry':
                trace('Loader: "Geometry" is no longer supported.');
                break;
            case 'object':
                var loader = new three.ObjectLoader();
                loader.setResourcePath(texturePath);
                loader.parse(data, function(result) {
                    editor.execute(new AddObjectCommand(editor, result));
                });
                break;
            case 'app':
                editor.fromJSON(data);
                break;
        }
    }

    async function handleZIP(contents:ArrayBuffer) {
        var zip = unzipSync(contents);
        var manager = new three.LoadingManager();
        manager.setURLModifier(function(url) {
            var file = zip[url];
            if (file) {
                trace('Loading $url');
                var blob = new Blob([file.buffer], { type: 'application/octet-stream' });
                return URL.createObjectURL(blob);
            }
            return url;
        });
        // Poly
        if (zip['model.obj'] && zip['materials.mtl']) {
            var MTLLoader = cast three.addons.loaders.MTLLoader(
                untyped __js__(await import('three/addons/loaders/MTLLoader.js'))
            );
            var OBJLoader = cast three.addons.loaders.OBJLoader(
                untyped __js__(await import('three/addons/loaders/OBJLoader.js'))
            );
            var materials = new MTLLoader(manager).parse(
                untyped __js__('String').from(zip['materials.mtl'])
            );
            var object = new OBJLoader().setMaterials(materials).parse(
                untyped __js__('String').from(zip['model.obj'])
            );
            editor.execute(new AddObjectCommand(editor, object));
            return;
        }
        //
        for (path in zip) {
            var file = zip[path];
            var extension = path.split('.').pop().toLowerCase();
            switch (extension) {
                case 'fbx':
                    var FBXLoader = cast three.addons.loaders.FBXLoader(
                        untyped __js__(await import('three/addons/loaders/FBXLoader.js'))
                    );
                    var loader = new FBXLoader(manager);
                    var object = loader.parse(file.buffer);
                    editor.execute(new AddObjectCommand(editor, object));
                    break;
                case 'glb':
                    var loader = await createGLTFLoader();
                    loader.parse(file.buffer, '', function(result) {
                        var scene = result.scene;
                        scene.animations.push(...result.animations);
                        editor.execute(new AddObjectCommand(editor, scene));
                        loader.dracoLoader.dispose();
                        loader.ktx2Loader.dispose();
                    });
                    break;
                case 'gltf':
                    var loader = await createGLTFLoader(manager);
                    loader.parse(untyped __js__('String').from(file), '', function(result) {
                        var scene = result.scene;
                        scene.animations.push(...result.animations);
                        editor.execute(new AddObjectCommand(editor, scene));
                        loader.dracoLoader.dispose();
                        loader.ktx2Loader.dispose();
                    });
                    break;
            }
        }
    }

    async function createGLTFLoader(manager:three.LoadingManager = null):GLTFLoader {
        var GLTFLoader = cast three.addons.loaders.GLTFLoader(
            untyped __js__(await import('three/addons/loaders/GLTFLoader.js'))
        );
        var DRACOLoader = cast three.addons.libs.draco.DRACOLoader(
            untyped __js__(await import('three/addons/libs/draco/DRACOLoader.js'))
        );
        var KTX2Loader = cast three.examples.jsm.libs.basis.KTX2Loader(
            untyped __js__(await import('three/addons/libs/basis/KTX2Loader.js'))
        );
        var MeshoptDecoder = cast three.addons.libs.meshopt_decoder.MeshoptDecoder(
            untyped __js__(await import('three/addons/libs/meshopt_decoder.module.js'))
        );
        var dracoLoader = new DRACOLoader();
        dracoLoader.setDecoderPath('../examples/jsm/libs/draco/gltf/');
        var ktx2Loader = new KTX2Loader(manager);
        ktx2Loader.setTranscoderPath('../examples/jsm/libs/basis/');
        editor.signals.rendererDetectKTX2Support.dispatch(ktx2Loader);
        var loader = new GLTFLoader(manager);
        loader.setDRACOLoader(dracoLoader);
        loader.setKTX2Loader(ktx2Loader);
        loader.setMeshoptDecoder(MeshoptDecoder);
        return loader;
    }
}