package three.shader;

class EnvmapFragmentShader {
    public static var shader:String = '
#ifdef USE_ENVMAP

    #ifdef ENV_WORLDPOS

    var cameraToFrag:Vec3;

    if (isOrthographic) {
        cameraToFrag = normalize(new Vec3(-viewMatrix[0][2], -viewMatrix[1][2], -viewMatrix[2][2]));
    } else {
        cameraToFrag = normalize(new Vec3(vWorldPosition.x - cameraPosition.x, vWorldPosition.y - cameraPosition.y, vWorldPosition.z - cameraPosition.z));
    }

    // Transforming Normal Vectors with the Inverse Transformation
    var worldNormal:Vec3 = inverseTransformDirection(normal, viewMatrix);

    #ifdef ENVMAP_MODE_REFLECTION
        var reflectVec:Vec3 = reflect(cameraToFrag, worldNormal);
    #else
        var reflectVec:Vec3 = refract(cameraToFrag, worldNormal, refractionRatio);
    #endif

    #else
        var reflectVec:Vec3 = vReflect;
    #endif

    #ifdef ENVMAP_TYPE_CUBE
        var envColor:Vec4 = textureCube(envMap, envMapRotation * new Vec3(flipEnvMap * reflectVec.x, reflectVec.y, reflectVec.z));
    #else
        var envColor:Vec4 = new Vec4(0.0, 0.0, 0.0, 0.0);
    #endif

    #ifdef ENVMAP_BLENDING_MULTIPLY
        outgoingLight = mix(outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity);
    #elif defined(ENVMAP_BLENDING_MIX)
        outgoingLight = mix(outgoingLight, envColor.xyz, specularStrength * reflectivity);
    #elif defined(ENVMAP_BLENDING_ADD)
        outgoingLight += envColor.xyz * specularStrength * reflectivity;
    #endif

#endif
    ';
}