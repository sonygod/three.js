import js.html.File;
import js.html.Blob;
import js.html.URL;
import js.html.Window;
import js.html.document;
import flow.StringInput;
import flow.Element;
import BaseNodeEditor from '../BaseNodeEditor';
import NodeUtils from 'three/nodes/NodeUtils';

class FileEditor extends BaseNodeEditor {

    public var nameInput:StringInput;
    public var url:String;
    public var buffer:js.typedefs.ArrayBuffer;

    public function new(buffer:js.typedefs.ArrayBuffer = null, name:String = 'File') {
        super('File', NodeUtils.arrayBuffer(buffer), 250);
        this.nameInput = new StringInput(name).setReadOnly(true);
        this.add(new Element().add(this.nameInput));
        this.url = null;
        this.buffer = buffer;
    }

    public function set buffer(arrayBuffer:js.typedefs.ArrayBuffer) {
        if (this.url != null) {
            URL.revokeObjectURL(this.url);
        }
        this.value.value = arrayBuffer;
        this.url = null;
    }

    public function get buffer():js.typedefs.ArrayBuffer {
        return this.value.value;
    }

    public function getURL():String {
        if (this.url == null) {
            var blob:Blob = new Blob([this.buffer], { type: 'application/octet-stream' });
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