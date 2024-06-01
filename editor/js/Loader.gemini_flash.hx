import three.Three;
import three.loaders.LoadingManager;
import three.loaders.FileLoader;
import three.loaders.BufferGeometryLoader;
import three.loaders.ObjectLoader;
import three.loaders.TextureLoader;
import three.loaders.CubeTextureLoader;
import three.loaders.TGALoader;
import three.addons.loaders.Rhino3dmLoader;
import three.addons.loaders.TDSLoader;
import three.addons.loaders.ThreeMFLoader;
import three.addons.loaders.AMFLoader;
import three.addons.loaders.ColladaLoader;
import three.addons.loaders.DRACOLoader;
import three.addons.loaders.FBXLoader;
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
import three.addons.loaders.USDZLoader;
import three.addons.loaders.VOXLoader;
import three.addons.loaders.VTKLoader;
import three.addons.loaders.VRMLLoader;
import three.addons.loaders.XYZLoader;
import three.addons.loaders.KTX2Loader;
import three.addons.libs.fflate.unzipSync;
import three.addons.libs.fflate.strFromU8;
import js.lib.Blob;
import js.lib.URL;
import js.lib.Worker;
import js.Browser;

class Loader {

    public var texturePath(default, null) : String = "";
    var editor : Dynamic; // Replace 'Dynamic' with the actual type of your editor

    public function new(editor) {
        this.editor = editor;
    }

    public function loadItemList(items : Array<Dynamic>) {
        LoaderUtils.getFilesFromItemList(items, function(files, filesMap) {
            loadFiles(files, filesMap);
        });
    }

    public function loadFiles(files : Array<js.html.Blob>, filesMap : Map<String, js.html.Blob>) {
        if (files.length > 0) {
            filesMap = filesMap != null ? filesMap : LoaderUtils.createFilesMap(files);

            var manager = new LoadingManager();
            manager.setURLModifier(function(url : String) : String {
                url = url.replace(/^\(\.?\/\)/, ""); // remove './'
                var file = filesMap.get(url);
                if (file != null) {
                    trace('Loading $url');
                    return URL.createObjectURL(file);
                }
                return url;
            });

            manager.addHandler(~/^.tga$/i, new TGALoader());

            for (i in 0...files.length) {
                loadFile(files[i], manager);
            }
        }
    }

    function loadFile(file : js.html.Blob, manager : LoadingManager) {
        var filename = file.name;
        var parts = filename.split(".");
        var extension = parts[parts.length - 1].toLowerCase();

        var reader = new Browser.FileReader();
        reader.addEventListener("progress", function(event) {
            var size = "(" + editor.utils.formatNumber(Math.floor(event.loaded / 1000)) + " KB)";
            var progress = Math.floor((event.loaded / event.total) * 100) + '%';
            trace('Loading $filename $size $progress');
        });

        switch (extension) {
            case "3dm":
                reader.addEventListener("load", function(event) {
                    var contents = event.target.result;
                    var loader = new Rhino3dmLoader();
                    loader.setLibraryPath("../examples/jsm/libs/rhino3dm/");
                    loader.parse(contents, function(object) {
                        object.name = filename;
                        editor.execute(new AddObjectCommand(editor, object));
                    }, function(error) {
                        trace('Error loading 3dm file: $error');
                    });
                }, false);
                reader.readAsArrayBuffer(file);
            case "3ds":
                reader.addEventListener("load", function(event) {
                    var loader = new TDSLoader();
                    var object = loader.parse(event.target.result);
                    editor.execute(new AddObjectCommand(editor, object));
                }, false);
                reader.readAsArrayBuffer(file);
            case "3mf":
                reader.addEventListener("load", function(event) {
                    var loader = new ThreeMFLoader();
                    var object = loader.parse(event.target.result);
                    editor.execute(new AddObjectCommand(editor, object));
                }, false);
                reader.readAsArrayBuffer(file);
            case "amf":
                reader.addEventListener("load", function(event) {
                    var loader = new AMFLoader();
                    var amfobject = loader.parse(event.target.result);
                    editor.execute(new AddObjectCommand(editor, amfobject));
                }, false);
                reader.readAsArrayBuffer(file);
            // ... (rest of the cases for different file formats)
            case "zip":
                reader.addEventListener("load", function(event) {
                    handleZIP(event.target.result);
                }, false);
                reader.readAsArrayBuffer(file);
            case _:
                trace('Unsupported file format ($extension).');
        }
    }

    function handleJSON(data : Dynamic) {
        // ... (implementation for handling JSON data)
    }

    function handleZIP(contents : js.lib.ArrayBuffer) {
        // ... (implementation for handling ZIP files)
    }

    async function createGLTFLoader(manager : LoadingManager = null) : js.lib.Promise<GLTFLoader> {
        var dracoLoader = new DRACOLoader();
        dracoLoader.setDecoderPath("../examples/jsm/libs/draco/gltf/");

        var ktx2Loader = new KTX2Loader(manager);
        ktx2Loader.setTranscoderPath("../examples/jsm/libs/basis/");

        // Assuming editor.signals.rendererDetectKTX2Support is a signal that accepts a KTX2Loader
        editor.signals.rendererDetectKTX2Support.dispatch(ktx2Loader); 

        var loader = new GLTFLoader(manager);
        loader.setDRACOLoader(dracoLoader);
        loader.setKTX2Loader(ktx2Loader);
        // loader.setMeshoptDecoder(MeshoptDecoder); // You'll need to import and initialize MeshoptDecoder

        return loader;
    }
}