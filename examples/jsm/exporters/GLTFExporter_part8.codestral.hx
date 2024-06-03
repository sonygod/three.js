import js.Array;
import js.html.WebGLRenderingContext;

class GLTFMaterialsTransmissionExtension {
    public var writer: GLTFWriter;
    public var name: String;

    public function new(writer: GLTFWriter) {
        this.writer = writer;
        this.name = 'KHR_materials_transmission';
    }

    public function writeMaterial(material: MeshPhysicalMaterial, materialDef: Dynamic) {
        if (!material.isMeshPhysicalMaterial || material.transmission === 0) return;

        var writer = this.writer;
        var extensionsUsed = writer.extensionsUsed;

        var extensionDef = new Dynamic();

        extensionDef.transmissionFactor = material.transmission;

        if (material.transmissionMap != null) {
            var transmissionMapDef = {
                index: writer.processTexture(material.transmissionMap),
                texCoord: material.transmissionMap.channel
            };
            writer.applyTextureTransform(transmissionMapDef, material.transmissionMap);
            extensionDef.transmissionTexture = transmissionMapDef;
        }

        if (materialDef.extensions == null) materialDef.extensions = new Dynamic();
        materialDef.extensions[this.name] = extensionDef;

        extensionsUsed[this.name] = true;
    }
}