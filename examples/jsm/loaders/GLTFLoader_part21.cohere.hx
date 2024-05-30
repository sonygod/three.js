class GLTFDracoMeshCompressionExtension {
    public var name:String;
    public var json:Json;
    public var dracoLoader:DracoLoader;

    public function new(json:Json, dracoLoader:DracoLoader) {
        if (dracoLoader == null) {
            throw $hxExceptions.EError("THREE.GLTFLoader: No DRACOLoader instance provided.");
        }

        this.name = EXTENSIONS.KHR_DRACO_MESH_COMPRESSION;
        this.json = json;
        this.dracoLoader = dracoLoader;
        this.dracoLoader.preload();
    }

    public function decodePrimitive(primitive:Dynamic, parser:GLTFLoader) : Promise<Geometry> {
        var json = this.json;
        var dracoLoader = this.dracoLoader;
        var bufferViewIndex = primitive.extensions[$hash<String>('bufferView')];
        var gltfAttributeMap = primitive.extensions[this.name].attributes;
        var threeAttributeMap = {};
        var attributeNormalizedMap = {};
        var attributeTypeMap = {};

        var keys = Reflect.fields(gltfAttributeMap);
        for (key in keys) {
            var attributeName = keys[key];
            var threeAttributeName = ATTRIBUTES.get(attributeName) ?? attributeName.toLowerCase();
            threeAttributeMap[threeAttributeName] = gltfAttributeMap[attributeName];
        }

        var primitiveAttributes = primitive.attributes;
        var primitiveAttributeKeys = Reflect.fields(primitiveAttributes);
        for (key in primitiveAttributeKeys) {
            var attributeName = primitiveAttributeKeys[key];
            var threeAttributeName = ATTRIBUTES.get(attributeName) ?? attributeName.toLowerCase();

            if (gltfAttributeMap.exists(attributeName)) {
                var accessorDef = json.accessors.get(primitiveAttributes[attributeName]);
                var componentType = WEBGL_COMPONENT_TYPES.get(accessorDef.componentType);

                attributeTypeMap[threeAttributeName] = componentType.name;
                attributeNormalizedMap[threeAttributeName] = accessorDef.normalized;
            }
        }

        var bufferViewPromise = parser.getDependency('bufferView', bufferViewIndex);
        return bufferViewPromise.then(function(bufferView) {
            return Promise.make(function(resolve, reject) {
                dracoLoader.decodeDracoFile(bufferView, function(geometry) {
                    var geometryAttributes = geometry.attributes;
                    var geometryAttributeKeys = Reflect.fields(geometryAttributes);
                    for (key in geometryAttributeKeys) {
                        var attributeName = geometryAttributeKeys[key];
                        var attribute = geometryAttributes[attributeName];
                        var normalized = attributeNormalizedMap.get(attributeName);

                        if (normalized != null) {
                            attribute.normalized = normalized;
                        }
                    }

                    resolve(geometry);
                }, threeAttributeMap, attributeTypeMap, LinearSRGBColorSpace, reject);
            });
        });
    }
}