import three.MeshPhysicalMaterial;

class GLTFMaterialsIorExtension {

    public var parser:Dynamic;
    public var name:String;

    public function new(parser) {

        this.parser = parser;
        this.name = "KHR_MATERIALS_IOR"; // Assuming EXTENSIONS.KHR_MATERIALS_IOR is a constant

    }

    public function getMaterialType(materialIndex:Int):Class<Dynamic> {

        var materialDef = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) {
            return null;
        }

        return MeshPhysicalMaterial;

    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):js.Promise<Void> {

        var materialDef = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) {
            return js.Promise.resolve();
        }

        var extension = materialDef.extensions[this.name];

        materialParams.ior = (extension.ior != null) ? extension.ior : 1.5;

        return js.Promise.resolve();

    }

}