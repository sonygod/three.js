import three.js.playground.editors.BaseNodeEditor;

class MaterialEditor extends BaseNodeEditor {

	public function new(name:String, material:Dynamic, width:Int = 300) {
		super(name, material, width);
	}

	public function get_material():Dynamic {
		return this.value;
	}

}