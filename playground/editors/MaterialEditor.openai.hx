package three.js.playground.editors;

import three.js.playground.BaseNodeEditor;

class MaterialEditor extends BaseNodeEditor {

    public function new(name:String, material:Dynamic, width:Int = 300) {
        super(name, material, width);
    }

    public var material(get, never):Dynamic;

    private function get_material():Dynamic {
        return value;
    }
}