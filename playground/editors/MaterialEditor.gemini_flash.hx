import BaseNodeEditor from "../BaseNodeEditor";

class MaterialEditor extends BaseNodeEditor {

    public function new(name:String, material:Dynamic, width:Int = 300) {
        super(name, material, width);
    }

    public function get material():Dynamic {
        return this.value;
    }

}