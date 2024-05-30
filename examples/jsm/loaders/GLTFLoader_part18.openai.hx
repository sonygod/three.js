package three.js.examples.jsm.loaders;

import js.html.Promise;
import js.lib.Uint8Array;
import js.lib.ArrayBuffer;

class GLTFMeshoptCompression {
    public var name:String;
    public var parser:Dynamic;

    public function new(parser:Dynamic) {
        this.name = EXTENSIONS.EXT_MESHOPT_COMPRESSION;
        this.parser = parser;
    }

    public function loadBufferView(index:Int):Promise<ArrayBuffer> {
        var json:Dynamic = this.parser.json;
        var bufferView:Dynamic = json.bufferViews[index];

        if (bufferView.extensions != null && bufferView.extensions[this.name] != null) {
            var extensionDef:Dynamic = bufferView.extensions[this.name];

            var bufferPromise:Promise<ArrayBuffer> = this.parser.getDependency('buffer', extensionDef.buffer);
            var decoder:Dynamic = this.parser.options.meshoptDecoder;

            if (decoder == null || !decoder.supported) {
                if (json.extensionsRequired != null && json.extensionsRequired.indexOf(this.name) >= 0) {
                    throw new js.Error('THREE.GLTFLoader: setMeshoptDecoder must be called before loading compressed files');
                } else {
                    return Promise.resolve(null);
                }
            }

            return bufferPromise.then(function(buffer:ArrayBuffer):Promise<ArrayBuffer> {
                var byteOffset:Int = extensionDef.byteOffset != null ? extensionDef.byteOffset : 0;
                var byteLength:Int = extensionDef.byteLength != null ? extensionDef.byteLength : 0;

                var count:Int = extensionDef.count;
                var stride:Int = extensionDef.byteStride;

                var source:Uint8Array = new Uint8Array(buffer, byteOffset, byteLength);

                if (decoder.decodeGltfBufferAsync != null) {
                    return decoder.decodeGltfBufferAsync(count, stride, source, extensionDef.mode, extensionDef.filter).then(function(result:ArrayBuffer) {
                        return result;
                    });
                } else {
                    return decoder.ready.then(function() {
                        var result:ArrayBuffer = new ArrayBuffer(count * stride);
                        decoder.decodeGltfBuffer(new Uint8Array(result), count, stride, source, extensionDef.mode, extensionDef.filter);
                        return result;
                    });
                }
            });
        } else {
            return Promise.resolve(null);
        }
    }
}