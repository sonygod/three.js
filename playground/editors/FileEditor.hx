package three.playground.editors;

import flow.StringInput;
import flow.Element;
import three.nodes.BaseNodeEditor;
import three.nodes.arrayBuffer;
import three.nodes.NodeUtils;

class FileEditor extends BaseNodeEditor {
    public var nameInput:StringInput;
    public var url:String;

    public function new(?buffer:Dynamic, ?name:String = 'File') {
        super('File', arrayBuffer(buffer), 250);

        this.nameInput = new StringInput(name).setReadOnly(true);

        this.add(new Element().add(this.nameInput));

        this.url = null;
    }

    public function set_buffer(buffer:Dynamic) {
        if (this.url != null) {
            js.Browser.URL.revokeObjectURL(this.url);
        }
        this.value.value = buffer;
        this.url = null;
    }

    public function get_buffer():Dynamic {
        return this.value.value;
    }

    public function getURL():String {
        if (this.url == null) {
            var blob = new js.html.Blob([this.buffer], { type: 'application/octet-stream' });
            this.url = js.Browser.URL.createObjectURL(blob);
        }
        return this.url;
    }

    public override function serialize(data:Dynamic) {
        super.serialize(data);
        data.buffer = NodeUtils.arrayBufferToBase64(this.buffer);
        data.name = this.nameInput.getValue();
    }

    public override function deserialize(data:Dynamic) {
        super.deserialize(data);
        this.buffer = NodeUtils.base64ToArrayBuffer(data.buffer);
        this.nameInput.setValue(data.name);
    }
}