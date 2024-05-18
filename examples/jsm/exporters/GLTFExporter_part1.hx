package three.js.examples.jsm.exporters;

import three.js.GLTFWriter;
import three.js.GLTFLightExtension;
import three.js.GLTFMaterialsUnlitExtension;
import three.js.GLTFMaterialsTransmissionExtension;
import three.js.GLTFMaterialsVolumeExtension;
import three.js.GLTFMaterialsIorExtension;
import three.js.GLTFMaterialsSpecularExtension;
import three.js.GLTFMaterialsClearcoatExtension;
import three.js.GLTFMaterialsDispersionExtension;
import three.js.GLTFMaterialsIridescenceExtension;
import three.js.GLTFMaterialsSheenExtension;
import three.js.GLTFMaterialsAnisotropyExtension;
import three.js.GLTFMaterialsEmissiveStrengthExtension;
import three.js.GLTFMaterialsBumpExtension;
import three.js.GLTFMeshGpuInstancing;

class GLTFExporter {
    private var pluginCallbacks:Array<Void->GLTFExtension>;

    public function new() {
        pluginCallbacks = [];

        register(function(writer) return new GLTFLightExtension(writer));
        register(function(writer) return new GLTFMaterialsUnlitExtension(writer));
        register(function(writer) return new GLTFMaterialsTransmissionExtension(writer));
        register(function(writer) return new GLTFMaterialsVolumeExtension(writer));
        register(function(writer) return new GLTFMaterialsIorExtension(writer));
        register(function(writer) return new GLTFMaterialsSpecularExtension(writer));
        register(function(writer) return new GLTFMaterialsClearcoatExtension(writer));
        register(function(writer) return new GLTFMaterialsDispersionExtension(writer));
        register(function(writer) return new GLTFMaterialsIridescenceExtension(writer));
        register(function(writer) return new GLTFMaterialsSheenExtension(writer));
        register(function(writer) return new GLTFMaterialsAnisotropyExtension(writer));
        register(function(writer) return new GLTFMaterialsEmissiveStrengthExtension(writer));
        register(function(writer) return new GLTFMaterialsBumpExtension(writer));
        register(function(writer) return new GLTFMeshGpuInstancing(writer));
    }

    public function register(callback:Void->GLTFExtension):GLTFExporter {
        if (pluginCallbacks.indexOf(callback) == -1) {
            pluginCallbacks.push(callback);
        }
        return this;
    }

    public function unregister(callback:Void->GLTFExtension):GLTFExporter {
        var index:Int = pluginCallbacks.indexOf(callback);
        if (index != -1) {
            pluginCallbacks.splice(index, 1);
        }
        return this;
    }

    /**
     * Parse scenes and generate GLTF output
     * @param  {Scene or [THREE.Scenes]} input   Scene or Array of THREE.Scenes
     * @param  {Function} onDone  Callback on completed
     * @param  {Function} onError  Callback on errors
     * @param  {Object} options options
     */
    public function parse(input:SceneOrScenes, onDone:Void->Void, onError:Void->Void, options:Dynamic) {
        var writer:GLTFWriter = new GLTFWriter();
        var plugins:Array<GLTFExtension> = [];

        for (i in 0...pluginCallbacks.length) {
            plugins.push(pluginCallbacks[i](writer));
        }

        writer.setPlugins(plugins);
        writer.write(input, onDone, options).catchError(onError);
    }

    public function parseAsync(input:SceneOrScenes, options:Dynamic):Promise<Void> {
        var scope:GLTFExporter = this;
        return Promise.create(function(resolve:Void->Void, reject:Void->Void) {
            scope.parse(input, resolve, reject, options);
        });
    }
}