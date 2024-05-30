import three.js.extras.core.DracoLoader;
import three.js.loaders.GLTFLoader;
import three.js.math.ColorSpace;

class GLTFDracoMeshCompressionExtension {

    public var name:String;
    public var json:Dynamic;
    public var dracoLoader:DracoLoader;

    public function new(json:Dynamic, dracoLoader:DracoLoader) {

        if (dracoLoader == null) {

            throw new Error("THREE.GLTFLoader: No DRACOLoader instance provided.");

        }

        this.name = GLTFLoader.EXTENSIONS.KHR_DRACO_MESH_COMPRESSION;
        this.json = json;
        this.dracoLoader = dracoLoader;
        this.dracoLoader.preload();

    }

    public function decodePrimitive(primitive:Dynamic, parser:Dynamic):Promise<Dynamic> {

        var json = this.json;
        var dracoLoader = this.dracoLoader;
        var bufferViewIndex = primitive.extensions[this.name].bufferView;
        var gltfAttributeMap = primitive.extensions[this.name].attributes;
        var threeAttributeMap = new Map<String, Dynamic>();
        var attributeNormalizedMap = new Map<String, Bool>();
        var attributeTypeMap = new Map<String, String>();

        for (attributeName in gltfAttributeMap) {

            var threeAttributeName = GLTFLoader.ATTRIBUTES[attributeName] || StringTools.toLowerCase(attributeName);

            threeAttributeMap.set(threeAttributeName, gltfAttributeMap[attributeName]);

        }

        for (attributeName in primitive.attributes) {

            var threeAttributeName = GLTFLoader.ATTRIBUTES[attributeName] || StringTools.toLowerCase(attributeName);

            if (gltfAttributeMap[attributeName] !== null) {

                var accessorDef = json.accessors[primitive.attributes[attributeName]];
                var componentType = GLTFLoader.WEBGL_COMPONENT_TYPES[accessorDef.componentType];

                attributeTypeMap.set(threeAttributeName, componentType.name);
                attributeNormalizedMap.set(threeAttributeName, accessorDef.normalized);

            }

        }

        return parser.getDependency("bufferView", bufferViewIndex).then(function(bufferView) {

            return new Promise(function(resolve, reject) {

                dracoLoader.decodeDracoFile(bufferView, function(geometry) {

                    for (attributeName in geometry.attributes) {

                        var attribute = geometry.attributes[attributeName];
                        var normalized = attributeNormalizedMap.get(attributeName);

                        if (normalized != null) attribute.normalized = normalized;

                    }

                    resolve(geometry);

                }, threeAttributeMap, attributeTypeMap, ColorSpace.LinearSRGB, reject);

            });

        });

    }

}