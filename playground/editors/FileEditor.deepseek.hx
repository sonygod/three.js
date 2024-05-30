import flow.StringInput;
import flow.Element;
import three.nodes.arrayBuffer;
import three.nodes.NodeUtils;
import BaseNodeEditor from '../BaseNodeEditor.js';

class FileEditor extends BaseNodeEditor {

	public function new(buffer:Null<ArrayBuffer> = null, name:String = 'File') {

		super('File', arrayBuffer(buffer), 250);

		this.nameInput = new StringInput(name).setReadOnly(true);

		this.add(new Element().add(this.nameInput));

		this.url = null;

	}

	public function set buffer(arrayBuffer:ArrayBuffer) {

		if (this.url !== null) {

			untyped __js__('URL.revokeObjectURL(this.url)');

		}

		this.value.value = arrayBuffer;
		this.url = null;

	}

	public function get buffer():ArrayBuffer {

		return this.value.value;

	}

	public function getURL():String {

		if (this.url === null) {

			var blob = untyped __js__('new Blob([this.buffer], { type: "application/octet-stream" })');

			this.url = untyped __js__('URL.createObjectURL(blob)');

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