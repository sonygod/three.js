import BaseNodeEditor.BaseNodeEditor;

class MaterialEditor extends BaseNodeEditor {

	public var material:Dynamic;

	public function new(name:String, material:Dynamic, width:Int = 300) {
		super(name, material, width);
		this.material = this.value;
	}

}