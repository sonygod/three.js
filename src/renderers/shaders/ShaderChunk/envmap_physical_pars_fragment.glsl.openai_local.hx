#if USE_ENVMAP

inline function getIBLIrradiance(normal:Vector3):Vector3 {

    #if ENVMAP_TYPE_CUBE_UV

        var worldNormal:Vector3 = inverseTransformDirection(normal, viewMatrix);
        var envMapColor:Vector4 = textureCubeUV(envMap, envMapRotation * worldNormal, 1.0);
        return PI * envMapColor.rgb * envMapIntensity;

    #else

        return new Vector3(0.0, 0.0, 0.0);

    #end

}

inline function getIBLRadiance(viewDir:Vector3, normal:Vector3, roughness:Float):Vector3 {

    #if ENVMAP_TYPE_CUBE_UV

        var reflectVec:Vector3 = reflect(-viewDir, normal);
        reflectVec = normalize(mix(reflectVec, normal, roughness * roughness));
        reflectVec = inverseTransformDirection(reflectVec, viewMatrix);
        var envMapColor:Vector4 = textureCubeUV(envMap, envMapRotation * reflectVec, roughness);
        return envMapColor.rgb * envMapIntensity;

    #else

        return new Vector3(0.0, 0.0, 0.0);

    #end

}

#if USE_ANISOTROPY

inline function getIBLAnisotropyRadiance(viewDir:Vector3, normal:Vector3, roughness:Float, bitangent:Vector3, anisotropy:Float):Vector3 {

    #if ENVMAP_TYPE_CUBE_UV

        // https://google.github.io/filament/Filament.md.html#lighting/imagebasedlights/anisotropy
        var bentNormal:Vector3 = cross(bitangent, viewDir);
        bentNormal = normalize(cross(bentNormal, bitangent));
        bentNormal = normalize(mix(bentNormal, normal, pow2(pow2(1.0 - anisotropy * (1.0 - roughness)))));
        return getIBLRadiance(viewDir, bentNormal, roughness);

    #else

        return new Vector3(0.0, 0.0, 0.0);

    #end

}

#end

#end