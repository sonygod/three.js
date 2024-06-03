import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.Loader;
import fflate.FFlate;
import js.html.DOMParser;
import js.html.Element;
import js.html.XMLDocument;

class VTKLoader extends Loader {

    public function new(manager: Loader.LoadingManager) {
        super(manager);
    }

    public function load(url: String, onLoad: (geometry: BufferGeometry) -> Void, onProgress: (event: ProgressEvent) -> Void, onError: (event: ErrorEvent) -> Void) {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(data: ArrayBuffer) {
            try {
                onLoad(scope.parse(data));
            } catch (e: Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(data: ArrayBuffer): BufferGeometry {
        function parseASCII(data: String): BufferGeometry {
            // Implementation of parseASCII function...
        }

        function parseBinary(data: ArrayBuffer): BufferGeometry {
            // Implementation of parseBinary function...
        }

        function Float32Concat(first: Float32Array, second: Float32Array): Float32Array {
            // Implementation of Float32Concat function...
        }

        function Int32Concat(first: Int32Array, second: Int32Array): Int32Array {
            // Implementation of Int32Concat function...
        }

        function parseXML(stringFile: String): BufferGeometry {
            // Implementation of parseXML function...
        }

        var textDecoder = new TextDecoder();

        var meta = textDecoder.decode(new Uint8Array(data, 0, 250)).split('\n');

        if (meta[0].indexOf('xml') !== -1) {
            return parseXML(textDecoder.decode(data));
        } else if (meta[2].includes('ASCII')) {
            return parseASCII(textDecoder.decode(data));
        } else {
            return parseBinary(data);
        }
    }
}