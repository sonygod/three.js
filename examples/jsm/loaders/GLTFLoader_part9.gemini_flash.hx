import three.MeshPhysicalMaterial;
import three.MaterialsParameters;

class GLTFMaterialsTransmissionExtension {

    var parser:GLTFParser;
    var name:String;

    public function new(parser:GLTFParser) {

        this.parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_TRANSMISSION;

    }

    public function getMaterialType(materialIndex:Int):Class<Dynamic> {

        var materialDef = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) {
            return null;
        }

        return MeshPhysicalMaterial;

    }

    public function extendMaterialParams(materialIndex:Int, materialParams:MaterialsParameters):Promise<Void> {

        var materialDef = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) {

            return Promise.resolve();

        }

        var pending:Array<Promise<Void>> = [];

        var extension = Reflect.field(materialDef.extensions, this.name);

        if (Reflect.hasField(extension, "transmissionFactor")) {

            materialParams.transmission = Reflect.field(extension, "transmissionFactor");

        }

        if (Reflect.hasField(extension, "transmissionTexture")) {

            pending.push(parser.assignTexture(materialParams, "transmissionMap", Reflect.field(extension, "transmissionTexture")));

        }

        return Promise.all(pending);

    }

}