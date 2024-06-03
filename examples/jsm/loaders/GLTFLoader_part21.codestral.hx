class GLTFDracoMeshCompressionExtension {

    public var name:String;
    public var json:Dynamic;
    public var dracoLoader:DRACOLoader;

    public function new(json:Dynamic, dracoLoader:DRACOLoader) {

        if (dracoLoader == null) {

            throw "THREE.GLTFLoader: No DRACOLoader instance provided.";

        }

        this.name = EXTENSIONS.KHR_DRACO_MESH_COMPRESSION;
        this.json = json;
        this.dracoLoader = dracoLoader;
        this.dracoLoader.preload();

    }

    public function decodePrimitive(primitive:Dynamic, parser:GLTFParser):Promise<Geometry> {

        var bufferViewIndex = primitive.extensions[this.name].bufferView;
        var gltfAttributeMap = primitive.extensions[this.name].attributes;
        var threeAttributeMap = new haxe.ds.StringMap<Int>();
        var attributeNormalizedMap = new haxe.ds.StringMap<Bool>();
        var attributeTypeMap = new haxe.ds.StringMap<String>();

        for (attributeName in gltfAttributeMap.keys()) {

            var threeAttributeName = ATTRIBUTES.exists(attributeName) ? ATTRIBUTES.get(attributeName) : attributeName.toLowerCase();

            threeAttributeMap.set(threeAttributeName, gltfAttributeMap.get(attributeName));

        }

        for (attributeName in primitive.attributes.keys()) {

            var threeAttributeName = ATTRIBUTES.exists(attributeName) ? ATTRIBUTES.get(attributeName) : attributeName.toLowerCase();

            if (gltfAttributeMap.exists(attributeName)) {

                var accessorDef = this.json.accessors[primitive.attributes.get(attributeName)];
                var componentType = WEBGL_COMPONENT_TYPES[accessorDef.componentType];

                attributeTypeMap.set(threeAttributeName, componentType.name);
                attributeNormalizedMap.set(threeAttributeName, accessorDef.normalized == true);

            }

        }

        return parser.getDependency('bufferView', bufferViewIndex).then(function (bufferView) {

            return new Promise(function (resolve, reject) {

                dracoLoader.decodeDracoFile(bufferView, function (geometry) {

                    for (attributeName in geometry.attributes.keys()) {

                        var attribute = geometry.attributes.get(attributeName);
                        var normalized = attributeNormalizedMap.get(attributeName);

                        if (normalized != null) attribute.normalized = normalized;

                    }

                    resolve(geometry);

                }, threeAttributeMap, attributeTypeMap, LinearSRGBColorSpace, reject);

            });

        });

    }

}