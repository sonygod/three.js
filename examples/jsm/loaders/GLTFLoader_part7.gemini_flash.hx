import three.MeshPhysicalMaterial;

class GLTFMaterialsIridescenceExtension {

    public var parser(get, never):GLTFParser;
    inline function get_parser():GLTFParser { return this._parser; }
    var _parser:GLTFParser;

    public var name:String;

    public function new(parser:GLTFParser) {

        this._parser = parser;
        this.name = EXTENSIONS.KHR_MATERIALS_IRIDESCENCE;

    }

    public function getMaterialType(materialIndex:Int):Class<Dynamic> {

        var materialDef = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) {
            return null;
        }

        return MeshPhysicalMaterial;

    }

    public function extendMaterialParams(materialIndex:Int, materialParams:Dynamic):Promise<Array<Dynamic>> {

        var materialDef = parser.json.materials[materialIndex];

        if (materialDef.extensions == null || !Reflect.hasField(materialDef.extensions, this.name)) {
            return Promise.resolve([]);
        }

        var pending:Array<Promise<Dynamic>> = [];

        var extension = Reflect.field(materialDef.extensions, this.name);

        if (Reflect.hasField(extension, 'iridescenceFactor')) {

            Reflect.setField(materialParams, 'iridescence', Reflect.field(extension, 'iridescenceFactor'));

        }

        if (Reflect.hasField(extension, 'iridescenceTexture')) {

            pending.push(parser.assignTexture(materialParams, 'iridescenceMap', Reflect.field(extension, 'iridescenceTexture')));

        }

        if (Reflect.hasField(extension, 'iridescenceIor')) {

            Reflect.setField(materialParams, 'iridescenceIOR', Reflect.field(extension, 'iridescenceIor'));

        }

        if (!Reflect.hasField(materialParams, 'iridescenceThicknessRange')) {

            Reflect.setField(materialParams, 'iridescenceThicknessRange', [100, 400]);

        }

        if (Reflect.hasField(extension, 'iridescenceThicknessMinimum')) {

            Reflect.setField(Reflect.field(materialParams, 'iridescenceThicknessRange'), '0', Reflect.field(extension, 'iridescenceThicknessMinimum'));

        }

        if (Reflect.hasField(extension, 'iridescenceThicknessMaximum')) {

            Reflect.setField(Reflect.field(materialParams, 'iridescenceThicknessRange'), '1', Reflect.field(extension, 'iridescenceThicknessMaximum'));

        }

        if (Reflect.hasField(extension, 'iridescenceThicknessTexture')) {

            pending.push(parser.assignTexture(materialParams, 'iridescenceThicknessMap', Reflect.field(extension, 'iridescenceThicknessTexture')));

        }

        return Promise.all(pending);

    }

}