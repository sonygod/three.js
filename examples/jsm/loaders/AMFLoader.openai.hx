package three.js.examples.jsm.loaders;

import three.js.BufferGeometry;
import three.js.Color;
import three.js.FileLoader;
import three.js.Float32BufferAttribute;
import three.js.Group;
import three.js.Loader;
import three.js.Mesh;
import three.js.MeshPhongMaterial;
import fflate.Fflate;

class AMFLoader extends Loader {
    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:(object:Dynamic)->Void, onProgress:(event:ProgressEvent)->Void, onError:(event:ErrorEvent)->Void):Void {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(data:ArrayBuffer) {
            try {
                onLoad(scope.parse(data));
            } catch (e:Error) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    private function parse(data:ArrayBuffer):Dynamic {
        function loadDocument(data:ArrayBuffer):Xml {
            // ...
        }

        function loadDocumentScale(xml:Xml):Float {
            // ...
        }

        function loadMaterials(xml:Xml):{id:String, material:MeshPhongMaterial} {
            // ...
        }

        function loadColor(xml:Xml):{r:Float, g:Float, b:Float, a:Float} {
            // ...
        }

        function loadMeshVolume(xml:Xml):{name:String, triangles:Array<Float>, materialId:String} {
            // ...
        }

        function loadMeshVertices(xml:Xml):{vertices:Array<Float>, normals:Array<Float>} {
            // ...
        }

        function loadObject(xml:Xml):{id:String, obj:Dynamic} {
            // ...
        }

        var xml = loadDocument(data);
        var amfName = '';
        var amfAuthor = '';
        var amfScale = loadDocumentScale(xml);
        var amfMaterials = {};
        var amfObjects = {};

        for (child in xml.documentElement.childNodes) {
            // ...
        }

        var sceneObject = new Group();
        sceneObject.name = amfName;
        sceneObject.userData.author = amfAuthor;
        sceneObject.userData.loader = 'AMF';

        for (id in amfObjects) {
            var part = amfObjects[id];
            var meshes = part.meshes;
            var newObject = new Group();
            newObject.name = part.name;

            for (mesh in meshes) {
                // ...
            }
        }

        return sceneObject;
    }
}