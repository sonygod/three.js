package three.js.playground.editors;

import js.html.URL;
import js.html.Blob;
import three.nodes.ArrayBuffer;
import three.nodes.NodeUtils;
import flow.StringInput;
import flow.Element;

class FileEditor extends BaseNodeEditor {
    public var nameInput:StringInput;
    public var url:String;

    public function new(?buffer:ArrayBuffer, ?name:String = 'File') {
        super('File', ArrayBuffer.fromBuffer(buffer), 250);
        this.nameInput = new StringInput(name).setReadOnly(true);
        this.add(new Element().add(this.nameInput));
        this.url = null;
    }

    public function set_buffer(buffer:ArrayBuffer) {
        if (this.url != null) {
            URL.revokeObjectURL(this.url);
        }
        this.value.value = buffer;
        this.url = null;
    }

    public function get_buffer():ArrayBuffer {
        return this.value.value;
    }

    public function getURL():String {
        if (this.url == null) {
            var blob = new Blob([this.buffer], { type: 'application/octet-stream' });
            this.url = URL.createObjectURL(blob);
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