package three.js.examples.jso.loaders;

import three.js.loaders.draco.DracoLoader;
import three.js.loaders.gltf.GLTFLoader;

class GLTFDracoMeshCompressionExtension {
    public var name:String = EXTENSIONS.KHR_DRACO_MESH_COMPRESSION;
    public var json:Dynamic;
    public var dracoLoader:DracoLoader;

    public function new(json:Dynamic, dracoLoader:DracoLoader) {
        if (dracoLoader == null) {
            throw new Error("THREE.GLTFLoader: No DRACOLoader instance provided.");
        }
        this.json = json;
        this.dracoLoader = dracoLoader;
        dracoLoader.preload();
    }

    public function decodePrimitive(primitive:Dynamic, parser:Dynamic):Promise<Geometry> {
        var json:Dynamic = this.json;
        var dracoLoader:DracoLoader = this.dracoLoader;
        var bufferViewIndex:Int = primitive.extensions[this.name].bufferView;
        var gltfAttributeMap:Dynamic = primitive.extensions[this.name].attributes;
        var threeAttributeMap:Dynamic = {};
        var attributeNormalizedMap:Dynamic = {};
        var attributeTypeMap:Dynamic = {};

        for (attributeName in gltfAttributeMap.keys()) {
            var threeAttributeName:String = ATTRIBUTES[attributeName] != null ? ATTRIBUTES[attributeName] : attributeName.toLowerCase();
            threeAttributeMap[threeAttributeName] = gltfAttributeMap[attributeName];
        }

        for (attributeName in primitive.attributes.keys()) {
            var threeAttributeName:String = ATTRIBUTES[attributeName] != null ? ATTRIBUTES[attributeName] : attributeName.toLowerCase();
            if (gltfAttributeMap.exists(attributeName)) {
                var accessorDef:Dynamic = json.accessors[primitive.attributes[attributeName]];
                var componentType:Dynamic = WEBGL_COMPONENT_TYPES[accessorDef.componentType];
                attributeTypeMap[threeAttributeName] = componentType.name;
                attributeNormalizedMap[threeAttributeName] = accessorDef.normalized;
            }
        }

        return parser.getDependency('bufferView', bufferViewIndex).then(function(bufferView:Dynamic) {
            return new Promise(function(resolve:Geometry->Void, reject:Dynamic->Void) {
                dracoLoader.decodeDracoFile(bufferView, function(geometry:Geometry) {
                    for (attributeName in geometry.attributes.keys()) {
                        var attribute:Dynamic = geometry.attributes[attributeName];
                        var normalized:Bool = attributeNormalizedMap[attributeName];
                        if (normalized != null) attribute.normalized = normalized;
                    }
                    resolve(geometry);
                }, threeAttributeMap, attributeTypeMap, LinearSRGBColorSpace, reject);
            });
        });
    }
}