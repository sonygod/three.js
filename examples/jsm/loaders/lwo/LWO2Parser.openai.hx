package three.js.loaders.lwo;

import haxe.io.Bytes;

class LWO2Parser {
    var IFF:IffParser;

    public function new(IFF:IffParser) {
        this.IFF = IFF;
    }

    public function parseBlock() {
        IFF.debugger.offset = IFF.reader.tell();
        IFF.debugger.closeForms();

        var blockID:String = IFF.reader.getString(4);
        var length:Int = IFF.reader.getUint32();
        if (length > IFF.reader.length - IFF.reader.tell()) {
            IFF.reader.seek(IFF.reader.tell() - 4);
            length = IFF.reader.getUint16();
        }

        IFF.debugger.dataOffset = IFF.reader.tell();
        IFF.debugger.length = length;

        switch (blockID) {
            case 'FORM':
                IFF.parseForm(length);
                break;
            // Skipped chunks
            case 'ICON':
            case 'VMPA':
            case 'BBOX':
            // ...
                IFF.debugger.skipped = true;
                IFF.reader.seek(IFF.reader.tell() + length);
                break;
            case 'SURF':
                IFF.parseSurfaceLwo2(length);
                break;
            case 'CLIP':
                IFF.parseClipLwo2(length);
                break;
            // ...
            default:
                IFF.parseUnknownCHUNK(blockID, length);
        }

        if (blockID != 'FORM') {
            IFF.debugger.node = 1;
            IFF.debugger.nodeID = blockID;
            IFF.debugger.log();
        }

        if (IFF.reader.tell() >= IFF.currentFormEnd) {
            IFF.currentForm = IFF.parentForm;
        }
    }
}