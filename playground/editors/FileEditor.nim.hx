import StringInput.StringInput;
import Element.Element;
import BaseNodeEditor.BaseNodeEditor;
import arrayBuffer.arrayBuffer;
import NodeUtils.NodeUtils;

class FileEditor extends BaseNodeEditor {

	var nameInput:StringInput;
	var url:Null<String>;

	public function new(buffer:Null<ArrayBuffer> = null, name:String = 'File') {

		super('File', arrayBuffer(buffer), 250);

		this.nameInput = new StringInput(name).setReadOnly(true);

		this.add(new Element().add(this.nameInput));

		this.url = null;

	}

	public function set buffer(value:ArrayBuffer) {

		if (this.url != null) {

			js.Browser.window.URL.revokeObjectURL(this.url);

		}

		this.value.value = value;
		this.url = null;

	}

	public function get buffer():ArrayBuffer {

		return this.value.value;

	}

	public function getURL():String {

		if (this.url == null) {

			var blob = new Blob([this.buffer], {type: 'application/octet-stream'});

			this.url = js.Browser.window.URL.createObjectURL(blob);

		}

		return this.url;

	}

	public function serialize(data:Dynamic) {

		super.serialize(data);

		data.buffer = NodeUtils.arrayBufferToBase64(this.buffer);
		data.name = this.nameInput.getValue();

	}

	public function deserialize(data:Dynamic) {

		super.deserialize(data);

		this.buffer = NodeUtils.base64ToArrayBuffer(data.buffer);
		this.nameInput.setValue(data.name);

	}

}