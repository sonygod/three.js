package three.js.examples.jm.exporters;

import js.three.GLTFWriter;
import js.three.GLTFLightExtension;
import js.three.GLTFMaterialsUnlitExtension;
import js.three.GLTFMaterialsTransmissionExtension;
import js.three.GLTFMaterialsVolumeExtension;
import js.three.GLTFMaterialsIorExtension;
import js.three.GLTFMaterialsSpecularExtension;
import js.three.GLTFMaterialsClearcoatExtension;
import js.three.GLTFMaterialsDispersionExtension;
import js.three.GLTFMaterialsIridescenceExtension;
import js.three.GLTFMaterialsSheenExtension;
import js.three.GLTFMaterialsAnisotropyExtension;
import js.three.GLTFMaterialsEmissiveStrengthExtension;
import js.three.GLTFMaterialsBumpExtension;
import js.three.GLTFMeshGpuInstancing;

class GLTFExporter {
    public var pluginCallbacks:Array<Void->Void>;

    public function new() {
        pluginCallbacks = [];

        register(function(writer) {
            return new GLTFLightExtension(writer);
        });

        register(function(writer) {
            return new GLTFMaterialsUnlitExtension(writer);
        });

        register(function(writer) {
            return new GLTFMaterialsTransmissionExtension(writer);
        });

        register(function(writer) {
            return new GLTFMaterialsVolumeExtension(writer);
        });

        register(function(writer) {
            return new GLTFMaterialsIorExtension(writer);
        });

        register(function(writer) {
            return new GLTFMaterialsSpecularExtension(writer);
        });

        register(function(writer) {
            return new GLTFMaterialsClearcoatExtension(writer);
        });

        register(function(writer) {
            return new GLTFMaterialsDispersionExtension(writer);
        });

        register(function(writer) {
            return new GLTFMaterialsIridescenceExtension(writer);
        });

        register(function(writer) {
            return new GLTFMaterialsSheenExtension(writer);
        });

        register(function(writer) {
            return new GLTFMaterialsAnisotropyExtension(writer);
        });

        register(function(writer) {
            return new GLTFMaterialsEmissiveStrengthExtension(writer);
        });

        register(function(writer) {
            return new GLTFMaterialsBumpExtension(writer);
        });

        register(function(writer) {
            return new GLTFMeshGpuInstancing(writer);
        });
    }

    public function register(callback:Void->Void):GLTFExporter {
        if (pluginCallbacks.indexOf(callback) == -1) {
            pluginCallbacks.push(callback);
        }
        return this;
    }

    public function unregister(callback:Void->Void):GLTFExporter {
        if (pluginCallbacks.indexOf(callback) != -1) {
            pluginCallbacks.splice(pluginCallbacks.indexOf(callback), 1);
        }
        return this;
    }

    /**
     * Parse scenes and generate GLTF output
     * @param  input  Scene or Array of THREE.Scenes
     * @param  onDone  Callback on completed
     * @param  onError  Callback on errors
     * @param  options options
     */
    public function parse(input:Dynamic, onDone:Void->Void, onError:Void->Void, options:Dynamic):Void {
        var writer = new GLTFWriter();
        var plugins:Array<Dynamic> = [];

        for (i in 0...pluginCallbacks.length) {
            plugins.push(pluginCallbacks[i](writer));
        }

        writer.setPlugins(plugins);
        writer.write(input, onDone, options).catchError(onError);
    }

    public function parseAsync(input:Dynamic, options:Dynamic):Promise<Void> {
        var scope:GLTFExporter = this;
        return Promise.create(function(resolve:Void->Void, reject:Void->Void) {
            scope.parse(input, resolve, reject, options);
        });
    }
}