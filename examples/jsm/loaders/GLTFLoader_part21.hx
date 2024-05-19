package three.js.examples.jsm.loaders;

import js.Promise;
import js.Error;

class GLTFDracoMeshCompressionExtension {
    public var name:String;
    public var json:Dynamic;
    public var dracoLoader:Dynamic;

    public function new(json:Dynamic, dracoLoader:Dynamic) {
        if (dracoLoader == null) {
            throw new Error('THREE.GLTFLoader: No DRACOLoader instance provided.');
        }

        this.name = EXTENSIONS.KHR_DRACO_MESH_COMPRESSION;
        this.json = json;
        this.dracoLoader = dracoLoader;
        dracoLoader.preload();
    }

    public function decodePrimitive(primitive:Dynamic, parser:Dynamic):Promise<Dynamic> {
        var json = this.json;
        var dracoLoader = this.dracoLoader;
        var bufferViewIndex = primitive.extensions[this.name].bufferView;
        var gltfAttributeMap = primitive.extensions[this.name].attributes;
        var threeAttributeMap:Dynamic = {};
        var attributeNormalizedMap:Dynamic = {};
        var attributeTypeMap:Dynamic = {};

        for (attributeName in gltfAttributeMap) {
            var threeAttributeName:String = ATTRIBUTES[attributeName] != null ? ATTRIBUTES[attributeName] : attributeName.toLowerCase();
            threeAttributeMap[threeAttributeName] = gltfAttributeMap[attributeName];
        }

        for (attributeName in primitive.attributes) {
            var threeAttributeName:String = ATTRIBUTES[attributeName] != null ? ATTRIBUTES[attributeName] : attributeName.toLowerCase();

            if (gltfAttributeMap[attributeName] != null) {
                var accessorDef = json.accessors[primitive.attributes[attributeName]];
                var componentType = WEBGL_COMPONENT_TYPES[accessorDef.componentType];

                attributeTypeMap[threeAttributeName] = componentType.name;
                attributeNormalizedMap[threeAttributeName] = accessorDef.normalized;
            }
        }

        return parser.getDependency('bufferView', bufferViewIndex).then(function(bufferView:Dynamic) {
            return new Promise(function(resolve:Dynamic, reject:Dynamic) {
                dracoLoader.decodeDracoFile(bufferView, function(geometry:Dynamic) {
                    for (attributeName in geometry.attributes) {
                        var attribute = geometry.attributes[attributeName];
                        var normalized = attributeNormalizedMap[attributeName];

                        if (normalized != null) attribute.normalized = normalized;
                    }

                    resolve(geometry);
                }, threeAttributeMap, attributeTypeMap, LinearSRGBColorSpace, reject);
            });
        });
    }
}