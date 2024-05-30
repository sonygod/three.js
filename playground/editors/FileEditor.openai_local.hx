import flow.StringInput;
import flow.Element;
import three.nodes.arrayBuffer;
import three.nodes.NodeUtils;
import BaseNodeEditor;

class FileEditor extends BaseNodeEditor {

    public var nameInput:StringInput;
    public var url:String = null;

    public function new(buffer:Dynamic = null, name:String = 'File') {
        super('File', arrayBuffer(buffer), 250);

        this.nameInput = new StringInput(name).setReadOnly(true);

        this.add(new Element().add(this.nameInput));
    }

    public function set_buffer(arrayBuffer:Dynamic):Void {
        if (this.url != null) {
            URL.revokeObjectURL(this.url);
        }

        this.value.value = arrayBuffer;
        this.url = null;
    }

    public function get_buffer():Dynamic {
        return this.value.value;
    }

    public function getURL():String {
        if (this.url == null) {
            var blob = new Blob([this.buffer], { type: 'application/octet-stream' });
            this.url = URL.createObjectURL(blob);
        }

        return this.url;
    }

    public override function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.buffer = NodeUtils.arrayBufferToBase64(this.buffer);
        data.name = this.nameInput.getValue();
    }

    public override function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        this.buffer = NodeUtils.base64ToArrayBuffer(data.buffer);
        this.nameInput.setValue(data.name);
    }
}