import js.BaseNodeEditor;

class MaterialEditor extends js.BaseNodeEditor {
	public function new(name:String, material:Dynamic, ?width:Int) {
		super(name, material, width ?? 300);
	}
	
	public function get_material():Dynamic {
		return this.value;
	}
}