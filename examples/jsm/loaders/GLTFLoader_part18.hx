Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.js.examples.jsm.loaders;

import js.html.Uint8Array;
import js.Promise;

class GLTFMeshoptCompression {
  public var name:String;
  public var parser:Dynamic;

  public function new(parser:Dynamic) {
    this.name = EXTENSIONS.EXT_MESHOPT_COMPRESSION;
    this.parser = parser;
  }

  public function loadBufferView(index:Int):Promise<js.html.ArrayBuffer> {
    var json:Dynamic = this.parser.json;
    var bufferView:Dynamic = json.bufferViews[index];

    if (bufferView.extensions && bufferView.extensions[this.name]) {
      var extensionDef:Dynamic = bufferView.extensions[this.name];

      var buffer:Promise<js.html.ArrayBuffer> = this.parser.getDependency('buffer', extensionDef.buffer);
      var decoder:Dynamic = this.parser.options.meshoptDecoder;

      if (!decoder || !decoder.supported) {
        if (json.extensionsRequired && json.extensionsRequired.indexOf(this.name) >= 0) {
          throw new Error('THREE.GLTFLoader: setMeshoptDecoder must be called before loading compressed files');
        } else {
          // Assumes that the extension is optional and that fallback buffer data is present
          return Promise.resolve(null);
        }
      }

      return buffer.then(function(res:js.html.ArrayBuffer) {
        var byteOffset:Int = extensionDef.byteOffset || 0;
        var byteLength:Int = extensionDef.byteLength || 0;

        var count:Int = extensionDef.count;
        var stride:Int = extensionDef.byteStride;

        var source:Uint8Array = new Uint8Array(res, byteOffset, byteLength);

        if (decoder.decodeGltfBufferAsync != null) {
          return decoder.decodeGltfBufferAsync(count, stride, source, extensionDef.mode, extensionDef.filter).then(function(res:js.html.ArrayBuffer) {
            return res;
          });
        } else {
          // Support for MeshoptDecoder 0.18 or earlier, without decodeGltfBufferAsync
          return decoder.ready.then(function() {
            var result:js.html.ArrayBuffer = new ArrayBuffer(count * stride);
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
```
Note that I've used the `js` package to import JavaScript types such as `Uint8Array` and `ArrayBuffer`. I've also used the `Promise` type to represent the asynchronous operations. I've kept the same naming conventions and coding style as the original JavaScript code.