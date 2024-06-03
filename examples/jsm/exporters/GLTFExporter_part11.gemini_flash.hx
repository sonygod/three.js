import haxe.io.Bytes;
import js.html.CanvasRenderingContext2D;

class GLTFMaterialsSpecularExtension {

  public var writer:GLTFWriter;
  public var name:String = "KHR_materials_specular";

  public function new(writer:GLTFWriter) {
    this.writer = writer;
  }

  public function writeMaterial(material:Dynamic, materialDef:Dynamic) {
    if (!Reflect.hasField(material, "isMeshPhysicalMaterial") ||
        !Reflect.hasField(material, "specularIntensity") || !Reflect.hasField(material, "specularColor") ||
        !Reflect.hasField(material, "specularIntensityMap") || !Reflect.hasField(material, "specularColorMap") ||
        (material.specularIntensity == 1.0 &&
         material.specularColor.equals(DEFAULT_SPECULAR_COLOR) &&
         material.specularIntensityMap == null && material.specularColorMap == null)) {
      return;
    }

    var extensionDef:Dynamic = {};

    if (material.specularIntensityMap != null) {
      var specularIntensityMapDef:Dynamic = {
        index: writer.processTexture(material.specularIntensityMap),
        texCoord: material.specularIntensityMap.channel
      };
      writer.applyTextureTransform(specularIntensityMapDef, material.specularIntensityMap);
      extensionDef.specularTexture = specularIntensityMapDef;
    }

    if (material.specularColorMap != null) {
      var specularColorMapDef:Dynamic = {
        index: writer.processTexture(material.specularColorMap),
        texCoord: material.specularColorMap.channel
      };
      writer.applyTextureTransform(specularColorMapDef, material.specularColorMap);
      extensionDef.specularColorTexture = specularColorMapDef;
    }

    extensionDef.specularFactor = material.specularIntensity;
    extensionDef.specularColorFactor = material.specularColor.toArray();

    materialDef.extensions = materialDef.extensions || {};
    materialDef.extensions[this.name] = extensionDef;

    writer.extensionsUsed[this.name] = true;
  }
}