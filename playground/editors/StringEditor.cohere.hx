import js.Browser.Event;

class StringEditor extends BaseNodeEditor {
	public function new() {
		var element = createElementFromJSON({
			inputType: 'string',
			inputConnection: false
		});
		super('String', element.inputNode, 350);
		var inputNode = element.inputNode;
		var this1 = inputNode;
		this1.addEventListener('changeInput', $bind(this, this.invalidate));
		this.add(inputNode);
	}

	public function get stringNode():String {
		return this.value;
	}

	public function getURL():String {
		return this.stringNode.value;
	}

}