package three.js.examples.jsm.loaders;

import js.html.Worker;
import js.html.MessageEvent;

class Rhino3dmLoader {
    private var libraryPending:Promise<Dynamic>;
    private var libraryConfig:Dynamic;
    private var rhino:Dynamic;
    private var taskID:Int;

    public function new() {}

    public function onMessage(event:MessageEvent) {
        var message = event.data;
        switch (message.type) {
            case 'init':
                libraryConfig = message.libraryConfig;
                var wasmBinary = libraryConfig.wasmBinary;
                var RhinoModule = { wasmBinary: wasmBinary, onRuntimeInitialized: function() {} };
                libraryPending = new Promise(function(resolve) {
                    RhinoModule.onRuntimeInitialized = resolve;
                    rhino3dm(RhinoModule);
                }).then(function() {
                    rhino = RhinoModule;
                });
                break;
            case 'decode':
                taskID = message.id;
                var buffer:ArrayBuffer = message.buffer;
                libraryPending.then(function() {
                    try {
                        var data = decodeObjects(rhino, buffer);
                        Worker.self.postMessage({ type: 'decode', id: message.id, data: data });
                    } catch (error) {
                        Worker.self.postMessage({ type: 'error', id: message.id, error: error });
                    }
                });
                break;
        }
    }

    private function decodeObjects(rhino:Dynamic, buffer:ArrayBuffer):Dynamic {
        // ...
    }

    private function extractObjectData(object:Dynamic, doc:Dynamic):Dynamic {
        // ...
    }

    private function extractProperties(object:Dynamic):Dynamic {
        // ...
    }

    private function extractTextures(m:Dynamic, tTypes:Array<Dynamic>, d:Dynamic):Array<Dynamic> {
        // ...
    }

    private function extractTextureData(t:Dynamic, tType:String, d:Dynamic):Dynamic {
        // ...
    }

    private function curveToPoints(curve:Dynamic, pointLimit:Int):Array<Dynamic> {
        // ...
    }
}