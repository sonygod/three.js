import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.xml.XmlParser;
import js.html.DataView;
import js.html.TextDecoder;
import js.html.Uint8Array;

class VTKLoader {
    public function new(manager:Dynamic) {
        // ...
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        // ...
    }

    private function parse(data:Bytes):BufferGeometry {
        var textDecoder = new TextDecoder();
        var meta = textDecoder.decode(data.sub(0, 250)).split('\n');

        if (meta[0].indexOf('xml') != -1) {
            return parseXML(textDecoder.decode(data));
        } else if (meta[2].includes('ASCII')) {
            return parseASCII(textDecoder.decode(data));
        } else {
            return parseBinary(data);
        }
    }

    private function parseASCII(data:String):BufferGeometry {
        // ...
    }

    private function parseBinary(data:Bytes):BufferGeometry {
        // ...
    }

    private function parseXML(stringFile:String):BufferGeometry {
        // ...
    }
}

class Color {
    public function new(r:Float, g:Float, b:Float) {
        // ...
    }

    public function set(r:Float, g:Float, b:Float):Void {
        // ...
    }

    public function convertSRGBToLinear():Void {
        // ...
    }
}

class BufferAttribute {
    public function new(array:Dynamic, itemSize:Int) {
        // ...
    }
}

class BufferGeometry {
    public function new():Void {
        // ...
    }

    public function setIndex(index:Dynamic):Void {
        // ...
    }

    public function setAttribute(name:String, attribute:Dynamic):Void {
        // ...
    }

    public function toNonIndexed():BufferGeometry {
        // ...
    }
}

class Float32BufferAttribute {
    public function new(array:Dynamic, itemSize:Int) {
        // ...
    }
}

class Uint32Array {
    public function new(length:Int) {
        // ...
    }
}

class Int32Array {
    public function new(length:Int) {
        // ...
    }
}

class Float32Array {
    public function new(length:Int) {
        // ...
    }
}

class DataView {
    public function getFloat32(byteOffset:Int, littleEndian:Bool):Float {
        // ...
    }

    public function getInt32(byteOffset:Int, littleEndian:Bool):Int {
        // ...
    }
}

class XmlParser {
    public static function run(str:String):Xml {
        // ...
    }
}

class Xml {
    public function getElements(tag:String):Array<Xml> {
        // ...
    }

    public function getAttribute(name:String):String {
        // ...
    }
}

class BytesInput {
    public function new(bytes:Bytes) {
        // ...
    }

    public function readInt32():Int {
        // ...
    }
}

class Bytes {
    public function sub(pos:Int, len:Int):Bytes {
        // ...
    }
}