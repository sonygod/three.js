class GLTFExporter {
    private var pluginCallbacks: Array<(GLTFWriter -> GLTFPlugin)> = new Array<(GLTFWriter -> GLTFPlugin)>();

    public function new() {
        register(writer -> new GLTFLightExtension(writer));
        register(writer -> new GLTFMaterialsUnlitExtension(writer));
        register(writer -> new GLTFMaterialsTransmissionExtension(writer));
        register(writer -> new GLTFMaterialsVolumeExtension(writer));
        register(writer -> new GLTFMaterialsIorExtension(writer));
        register(writer -> new GLTFMaterialsSpecularExtension(writer));
        register(writer -> new GLTFMaterialsClearcoatExtension(writer));
        register(writer -> new GLTFMaterialsDispersionExtension(writer));
        register(writer -> new GLTFMaterialsIridescenceExtension(writer));
        register(writer -> new GLTFMaterialsSheenExtension(writer));
        register(writer -> new GLTFMaterialsAnisotropyExtension(writer));
        register(writer -> new GLTFMaterialsEmissiveStrengthExtension(writer));
        register(writer -> new GLTFMaterialsBumpExtension(writer));
        register(writer -> new GLTFMeshGpuInstancing(writer));
    }

    public function register(callback: (GLTFWriter -> GLTFPlugin)): GLTFExporter {
        if (!pluginCallbacks.contains(callback)) {
            pluginCallbacks.push(callback);
        }
        return this;
    }

    public function unregister(callback: (GLTFWriter -> GLTFPlugin)): GLTFExporter {
        var index = pluginCallbacks.indexOf(callback);
        if (index != -1) {
            pluginCallbacks.splice(index, 1);
        }
        return this;
    }

    public function parse(input: dynamic, onDone: (Any -> Void), onError: (Dynamic -> Void), options: Dynamic): Void {
        var writer = new GLTFWriter();
        var plugins: Array<GLTFPlugin> = new Array<GLTFPlugin>();

        for (callback in pluginCallbacks) {
            plugins.push(callback(writer));
        }

        writer.setPlugins(plugins);
        writer.write(input, onDone, options).catch(onError);
    }

    public function parseAsync(input: dynamic, options: Dynamic): Promise<Any> {
        return new Promise<Any>((resolve, reject) -> {
            parse(input, resolve, reject, options);
        });
    }
}