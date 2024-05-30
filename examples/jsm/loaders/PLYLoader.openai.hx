import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Encoding;
import haxe.io.Eof;
import haxe.ds.Vector;

class PLYLoader extends Loader {
    public var propertyNameMapping:Dynamic;
    public var customPropertyMapping:Dynamic;

    public function new(manager:Loader) {
        super(manager);
        propertyNameMapping = {};
        customPropertyMapping = {};
    }

    public function load(url:String, onLoad:Array<BufferGeometry>->Void, onProgress:Int->Float->Void, onError:Error->Void) {
        var loader = new FileLoader(manager);
        loader.setPath(path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(requestHeader);
        loader.setWithCredentials(withCredentials);
        loader.load(url, function(data:ArrayBuffer) {
            try {
                onLoad(parse(data));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function setPropertyNameMapping(mapping:Dynamic) {
        propertyNameMapping = mapping;
    }

    public function setCustomPropertyNameMapping(mapping:Dynamic) {
        customPropertyMapping = mapping;
    }

    function parse(data:ArrayBuffer):BufferGeometry {
        var byteData:Bytes = Bytes.ofData(data);
        var headerText:String = extractHeaderText(byteData);
        var header = parseHeader(headerText);
        var geometry:BufferGeometry;

        if (header.format == 'ascii') {
            var asciiText:String = Bytes.bytesToString(byteData.sub(byteData.position, byteData.length));
            geometry = parseASCII(asciiText, header);
        } else {
            geometry = parseBinary(byteData, header);
        }

        return geometry;
    }

    function parseHeader(headerText:String, ?headerLength:Int = 0):Dynamic {
        // ...
    }

    function parseASCIINumber(n:String, type:String):Float {
        // ...
    }

    function parseASCIIElement(properties:Array<Dynamic>, tokens:ArrayStream):Dynamic {
        // ...
    }

    function createBuffer():Dynamic {
        // ...
    }

    function mapElementAttributes(properties:Array<Dynamic>):Dynamic {
        // ...
    }

    function parseASCII(data:String, header:Dynamic):BufferGeometry {
        // ...
    }

    function postProcess(buffer:Dynamic):BufferGeometry {
        // ...
    }

    function handleElement(buffer:Dynamic, elementName:String, element:Dynamic, cacheEntry:Dynamic) {
        // ...
    }

    function binaryReadElement(at:Int, properties:Array<Dynamic>):Array<Dynamic> {
        // ...
    }

    function setPropertyBinaryReaders(properties:Array<Dynamic>, body:Bytes, littleEndian:Bool) {
        // ...
    }

    function parseBinary(data:ArrayBuffer, header:Dynamic):BufferGeometry {
        // ...
    }

    function extractHeaderText(bytes:Bytes):{ headerText:String, headerLength:Int } {
        // ...
    }
}

class ArrayStream {
    var arr:Array<Dynamic>;
    var i:Int;

    public function new(arr:Array<Dynamic>) {
        this.arr = arr;
        this.i = 0;
    }

    public function empty():Bool {
        return i >= arr.length;
    }

    public function next():Dynamic {
        return arr[i++];
    }
}