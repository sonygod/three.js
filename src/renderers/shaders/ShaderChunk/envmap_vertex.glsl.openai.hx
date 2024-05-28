package three.shader;

class EnvmapVertexShader {
  public static var code:String = "

#ifdef USE_ENVMAP

  #ifdef ENV_WORLDPOS

    vWorldPosition = worldPosition.xyz;

  #else

    var cameraToVertex:Vec3;

    if (isOrthographic) {

      cameraToVertex = normalize(new Vec3(-viewMatrix[0][2], -viewMatrix[1][2], -viewMatrix[2][2]));

    } else {

      cameraToVertex = normalize(worldPosition.xyz - cameraPosition);

    }

    var worldNormal:Vec3 = inverseTransformDirection(transformedNormal, viewMatrix);

    #ifdef ENVMAP_MODE_REFLECTION

      vReflect = reflect(cameraToVertex, worldNormal);

    #else

      vReflect = refract(cameraToVertex, worldNormal, refractionRatio);

    #endif

  #endif

#endif
";
}