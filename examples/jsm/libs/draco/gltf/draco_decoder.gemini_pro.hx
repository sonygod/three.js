import draco_decoder_gltf;

class DracoDecoderModule {
  static get ready(): Promise<draco_decoder_gltf.Module> {
    return draco_decoder_gltf.Module.ready;
  }
}

if (typeof(exports) != "undefined" && typeof(module) != "undefined") {
  exports.DracoDecoderModule = DracoDecoderModule;
} else if (typeof(define) == "function" && define.amd) {
  define(function() {
    return DracoDecoderModule;
  });
} else if (typeof(exports) != "undefined") {
  exports.DracoDecoderModule = DracoDecoderModule;
}


**Explanation:**

1. **Import `draco_decoder_gltf`:** The Haxe code imports the generated Haxe wrapper for the Draco Decoder Module, which contains the `Module` class with the `ready` promise.

2. **`DracoDecoderModule` class:** A simple Haxe class is defined to hold the `ready` promise.

3. **Export:** The `DracoDecoderModule` class is exported for use in other Haxe projects.

**How to Use:**

1. **Build the Draco Decoder Module:** Ensure you have built the Draco Decoder Module using Emscripten.

2. **Generate Haxe Wrapper:** Use the Haxe `emscripten` library to generate a Haxe wrapper for the Draco Decoder Module's JavaScript code.

3. **Use the `ready` Promise:** Use the `DracoDecoderModule.ready` promise to access the Draco Decoder Module's functions and classes once the module is loaded and initialized.

**Example:**


import draco_decoder_gltf;

class Main {
  static function main() {
    DracoDecoderModule.ready.then(function(module) {
      // Access Draco Decoder Module functions and classes
      var decoder = new draco_decoder_gltf.Decoder(module);
      // ...
    });
  }
}