import js.flow.StringInput;
import js.flow.Element;
import js.three.nodes.NodeUtils;
import js.three.nodes.arrayBuffer;

class FileEditor extends BaseNodeEditor {
	public var url: String;
	public var nameInput: StringInput;

	public function new(buffer: Array<Int> = null, name: String = 'File') {
		super('File', arrayBuffer(buffer), 250);
		nameInput = new StringInput(name).setReadOnly(true);
		add(new Element().add(nameInput));
		this.url = null;
	}

	public function set_buffer(arrayBuffer: Array<Int>) {
		if (url != null) {
			URL.revokeObjectURL(url);
		}
		value.value = arrayBuffer;
		url = null;
	}

	public function get_buffer(): Array<Int> {
		return value.value;
	}

	public function getURL(): String {
		if (url == null) {
			var blob = new Blob([buffer], { type: 'application/octet-stream' });
			url = URL.createObjectURL(blob);
		}
		return url;
	}

	public override function serialize(data: Dynamic) {
		super.serialize(data);
		data.buffer = NodeUtils.arrayBufferToBase64(buffer);
		data.name = nameInput.getValue();
	}

	public override function deserialize(data: Dynamic) {
		super.deserialize(data);
		buffer = NodeUtils.base64ToArrayBuffer(data.buffer);
		nameInput.setValue(data.name);
	}
}