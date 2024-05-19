Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.js.examples.jsm.exporters;

class GLTFMaterialsAnisotropyExtension {
    private var writer:Dynamic;
    public var name(default, null):String;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'KHR_materials_anisotropy';
    }

    public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
        if (!material.isMeshPhysicalMaterial || material.anisotropy == 0.0) return;

        var writer:Dynamic = this.writer;
        var extensionsUsed:Dynamic = writer.extensionsUsed;

        var extensionDef:Dynamic = {};

        if (material.anisotropyMap != null) {
            var anisotropyMapDef:Dynamic = { index: writer.processTexture(material.anisotropyMap) };
            writer.applyTextureTransform(anisotropyMapDef, material.anisotropyMap);
            extensionDef.anisotropyTexture = anisotropyMapDef;
        }

        extensionDef.anisotropyStrength = material.anisotropy;
        extensionDef.anisotropyRotation = material.anisotropyRotation;

        materialDef.extensions = materialDef.extensions != null ? materialDef.extensions : {};
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}
```
Note that I've used the `Dynamic` type to represent the JavaScript `any` type, as Haxe does not have a direct equivalent. I've also kept the same naming conventions and coding style as the original JavaScript code. Let me know if you have any questions or need further assistance!