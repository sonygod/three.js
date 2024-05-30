class GLTFDracoMeshCompressionExtension {

    var name:String;
    var json:Dynamic;
    var dracoLoader:Dynamic;

    public function new(json:Dynamic, dracoLoader:Dynamic) {

        if (!dracoLoader) {

            throw 'THREE.GLTFLoader: No DRACOLoader instance provided.';

        }

        this.name = EXTENSIONS.KHR_DRACO_MESH_COMPRESSION;
        this.json = json;
        this.dracoLoader = dracoLoader;
        this.dracoLoader.preload();

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

            var threeAttributeName = ATTRIBUTES[attributeName] || attributeName.toLowerCase();

            threeAttributeMap[threeAttributeName] = gltfAttributeMap[attributeName];

        }

        for (attributeName in primitive.attributes) {

            var threeAttributeName = ATTRIBUTES[attributeName] || attributeName.toLowerCase();

            if (gltfAttributeMap[attributeName] !== undefined) {

                var accessorDef = json.accessors[primitive.attributes[attributeName]];
                var componentType = WEBGL_COMPONENT_TYPES[accessorDef.componentType];

                attributeTypeMap[threeAttributeName] = componentType.name;
                attributeNormalizedMap[threeAttributeName] = accessorDef.normalized === true;

            }

        }

        return parser.getDependency('bufferView', bufferViewIndex).then(function (bufferView) {

            return new Promise(function (resolve, reject) {

                dracoLoader.decodeDracoFile(bufferView, function (geometry) {

                    for (attributeName in geometry.attributes) {

                        var attribute = geometry.attributes[attributeName];
                        var normalized = attributeNormalizedMap[attributeName];

                        if (normalized !== undefined) attribute.normalized = normalized;

                    }

                    resolve(geometry);

                }, threeAttributeMap, attributeTypeMap, LinearSRGBColorSpace, reject);

            });

        });

    }

}