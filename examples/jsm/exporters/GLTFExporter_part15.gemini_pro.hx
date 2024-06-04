class GLTFMaterialsBumpExtension {
  var writer: GLTFWriter;
  var name: String = "EXT_materials_bump";

  public function new(writer: GLTFWriter) {
    this.writer = writer;
  }

  public function writeMaterial(material: MeshStandardMaterial, materialDef: Dynamic) {
    if (!material.isMeshStandardMaterial || (material.bumpScale == 1 && !material.bumpMap)) {
      return;
    }

    var writer = this.writer;
    var extensionsUsed = writer.extensionsUsed;

    var extensionDef = new Dynamic();

    if (material.bumpMap != null) {
      var bumpMapDef = new Dynamic();
      bumpMapDef.index = writer.processTexture(material.bumpMap);
      bumpMapDef.texCoord = material.bumpMap.channel;
      writer.applyTextureTransform(bumpMapDef, material.bumpMap);
      extensionDef.bumpTexture = bumpMapDef;
    }

    extensionDef.bumpFactor = material.bumpScale;

    materialDef.extensions = materialDef.extensions != null ? materialDef.extensions : new Dynamic();
    materialDef.extensions[this.name] = extensionDef;

    extensionsUsed[this.name] = true;
  }
}