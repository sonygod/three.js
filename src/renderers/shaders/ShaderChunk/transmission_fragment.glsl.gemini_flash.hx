class Main {
  public static function main():Void {
    var glsl = /* glsl */
    {
      "#ifdef USE_TRANSMISSION": {
        "material.transmission = transmission;": null,
        "material.transmissionAlpha = 1.0;": null,
        "material.thickness = thickness;": null,
        "material.attenuationDistance = attenuationDistance;": null,
        "material.attenuationColor = attenuationColor;": null,
        "#ifdef USE_TRANSMISSIONMAP": {
          "material.transmission *= texture2D( transmissionMap, vTransmissionMapUv ).r;": null,
        },
        "#ifdef USE_THICKNESSMAP": {
          "material.thickness *= texture2D( thicknessMap, vThicknessMapUv ).g;": null,
        },
        "vec3 pos = vWorldPosition;": null,
        "vec3 v = normalize( cameraPosition - pos );": null,
        "vec3 n = inverseTransformDirection( normal, viewMatrix );": null,
        "vec4 transmitted = getIBLVolumeRefraction(": {
          "n, v, material.roughness, material.diffuseColor, material.specularColor, material.specularF90,": null,
          "pos, modelMatrix, viewMatrix, projectionMatrix, material.dispersion, material.ior, material.thickness,": null,
          "material.attenuationColor, material.attenuationDistance );": null,
        },
        "material.transmissionAlpha = mix( material.transmissionAlpha, transmitted.a, material.transmission );": null,
        "totalDiffuse = mix( totalDiffuse, transmitted.rgb, material.transmission );": null,
      },
    };
  }
}