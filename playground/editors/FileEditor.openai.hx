package three.js.playground.editors;

import flow.StringInput;
import flow.Element;
import three.nodes.BaseNodeEditor;
import three.nodes.arrayBuffer;
import three.nodes.NodeUtils;

class FileEditor extends BaseNodeEditor {
    public var nameInput:StringInput;
    public var url:String;

    public function new(buffer:ByteArray = null, name:String = 'File') {
        super('File', arrayBuffer(buffer), 250);

        nameInput = new StringInput(name);
        nameInput.setReadOnly(true);

        var element = new Element();
        element.appendChild(nameInput);
        add(element);

        url = null;
    }

    public function set_buffer(buffer:ByteArray):Void {
        if (url != null) {
            URL.revokeObjectUR(url);
        }

        value.value = buffer;
        url = null;
    }

    public function get_buffer():ByteArray {
        return value.value;
    }

    public function getURL():String {
        if (url == null) {
            var blob = new Blob([buffer], { type: 'application/octet-stream' });
            url = URL.createObjectURL(blob);
        }

        return url;
    }

    override public function serialize(data:Dynamic):Void {
        super.serialize(data);

        data.buffer = NodeUtils.arrayBufferToBase64(buffer);
        data.name = nameInput.getValue();
    }

    override public function deserialize(data:Dynamic):Void {
        super.deserialize(data);

        buffer = NodeUtils.base64ToArrayBuffer(data.buffer);
        nameInput.setValue(data.name);
    }
}