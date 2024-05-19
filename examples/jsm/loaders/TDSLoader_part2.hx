package three.js.examples.jsm.loaders;

class Chunk {
    private var data:DataView;
    private var offset:Int;
    private var position:Int;
    private var debugMessage:Void->Void;
    private var id:Int;
    private var size:Int;
    private var end:Int;

    public function new(data:DataView, position:Int, debugMessage:Void->Void) {
        this.data = data;
        this.offset = position;
        this.position = position;
        this.debugMessage = debugMessage;

        if (Reflect.isFunction(debugMessage)) {
            this.debugMessage = function() {};
        }

        this.id = readWord();
        this.size = readDWord();
        this.end = this.offset + this.size;

        if (this.end > data.byteLength) {
            this.debugMessage('Bad chunk size for chunk at ' + position);
        }
    }

    public function readChunk():Chunk {
        if (endOfChunk) {
            return null;
        }

        try {
            var next = new Chunk(this.data, this.position, this.debugMessage);
            this.position += next.size;
            return next;
        } catch (e:Dynamic) {
            this.debugMessage('Unable to read chunk at ' + this.position);
            return null;
        }
    }

    public var hexId(get, never):String;

    private function get_hexId():String {
        return id.toString(16);
    }

    public var endOfChunk(get, never):Bool;

    private function get_endOfChunk():Bool {
        return this.position >= this.end;
    }

    public function readByte():Int {
        var v = data.getUint8(this.position, true);
        this.position += 1;
        return v;
    }

    public function readFloat():Float {
        try {
            var v = data.getFloat32(this.position, true);
            this.position += 4;
            return v;
        } catch (e:Dynamic) {
            this.debugMessage(e + ' ' + this.position + ' ' + data.byteLength);
            return 0;
        }
    }

    public function readInt():Int {
        var v = data.getInt32(this.position, true);
        this.position += 4;
        return v;
    }

    public function readShort():Int {
        var v = data.getInt16(this.position, true);
        this.position += 2;
        return v;
    }

    public function readDWord():Int {
        var v = data.getUint32(this.position, true);
        this.position += 4;
        return v;
    }

    public function readWord():Int {
        var v = data.getUint16(this.position, true);
        this.position += 2;
        return v;
    }

    public function readString():String {
        var s = '';
        var c = readByte();
        while (c != 0) {
            s += String.fromCharCode(c);
            c = readByte();
        }
        return s;
    }
}