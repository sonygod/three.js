import three.threemf.ColorSpace;
import three.threemf.Loader;
import three.threemf.Matrix4;
import three.threemf.Mesh;
import three.threemf.MeshPhongMaterial;
import three.threemf.MeshStandardMaterial;
import three.threemf.TextureLoader;
import js.typedarrays.ArrayBuffer;
import js.typedarrays.Uint8Array;
import js.flash.utils.TextDecoder;
import js.flash.utils.XML;
import js.flash.utils.XMLList;

class ThreeMFLoader extends Loader {

    public var availableExtensions:Array<Dynamic>;

    public function new(manager:Dynamic) {
        super(manager);
        this.availableExtensions = [];
    }

    public override function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function (buffer:ArrayBuffer) {
            try {
                onLoad(scope.parse(buffer));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    console.error(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(data:ArrayBuffer):Dynamic {
        var scope = this;
        var textureLoader = new TextureLoader(scope.manager);

        function loadDocument(data:ArrayBuffer):Dynamic {
            var zip:Dynamic;
            var file:Dynamic;

            var relsName:String;
            var modelRelsName:String;
            var modelPartNames:Array<String>;
            var texturesPartNames:Array<String>;

            var modelRels:Array<Dynamic>;
            var modelParts:Object;
            var printTicketParts:Object;
            var texturesParts:Object;

            var textDecoder = new TextDecoder();

            try {
                zip = three.threemf.fflate.unzipSync(new Uint8Array(data));
            } catch (e:Dynamic) {
                if (e instanceof ReferenceError) {
                    console.error('THREE.3MFLoader: fflate missing and file is compressed.');
                    return null;
                }
            }

            for (file in zip) {
                if (file.match(/_rels\/.rels$/)) {
                    relsName = file;
                } else if (file.match(/3D\/_rels\/.*\.model\.rels$/)) {
                    modelRelsName = file;
                } else if (file.match(/^3D\/.*\.model$/)) {
                    modelPartNames.push(file);
                } else if (file.match(/^3D\/Textures?\/.*/)) {
                    texturesPartNames.push(file);
                }
            }

            if (relsName == undefined) throw new Error('THREE.ThreeMFLoader: Cannot find relationship file `rels` in 3MF archive.');

            var relsView = zip[relsName];
            var relsFileText = textDecoder.decode(relsView);
            var rels = parseRelsXml(relsFileText);

            if (modelRelsName) {
                var relsView = zip[modelRelsName];
                var relsFileText = textDecoder.decode(relsView);
                modelRels = parseRelsXml(relsFileText);
            }

            for (var i = 0; i < modelPartNames.length; i++) {
                var modelPart = modelPartNames[i];
                var view = zip[modelPart];

                var fileText = textDecoder.decode(view);
                var xmlData = new XML(fileText);

                if (xmlData.documentElement.nodeName.toLowerCase() != 'model') {
                    console.error('THREE.3FLoader: Error loading 3MF - no 3MF document found: ', modelPart);
                }

                var modelNode = xmlData.querySelector('model');
                var extensions = {};

                for (var i = 0; i < modelNode.attributes.length; i++) {
                    var attr = modelNode.attributes[i];
                    if (attr.name.match(/^xmlns:(.+)$/)) {
                        extensions[attr.value] = RegExp.$1;
                    }
                }

                var modelData = parseModelNode(modelNode);
                modelData['xml'] = modelNode;

                if (0 < Object.keys(extensions).length) {
                    modelData['extensions'] = extensions;
                }

                modelParts[modelPart] = modelData;
            }

            for (var i = 0; i < texturesPartNames.length; i++) {
                var texturesPartName = texturesPartNames[i];
                texturesParts[texturesPartName] = zip[texturesPartName].buffer;
            }

            return {
                rels:rels,
                modelRels:modelRels,
                model