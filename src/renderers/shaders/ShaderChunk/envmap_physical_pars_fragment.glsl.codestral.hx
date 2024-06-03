class EnvMapPhysicalParsFragment {
    public static function getIBLIrradiance(normal:FloatVector3):FloatVector3 {
        #ifdef USE_ENVMAP
        #ifdef ENVMAP_TYPE_CUBE_UV
            var worldNormal = normal.transformDirection(viewMatrix.inverse());
            var envMapColor = textureCubeUV(envMap, envMapRotation.multiply(worldNormal), 1.0);
            return new FloatVector3(Math.PI * envMapColor.r, Math.PI * envMapColor.g, Math.PI * envMapColor.b).multiply(envMapIntensity);
        #else
            return new FloatVector3(0.0, 0.0, 0.0);
        #endif
        #else
            return new FloatVector3(0.0, 0.0, 0.0);
        #endif
    }

    public static function getIBLRadiance(viewDir:FloatVector3, normal:FloatVector3, roughness:Float):FloatVector3 {
        #ifdef USE_ENVMAP
        #ifdef ENVMAP_TYPE_CUBE_UV
            var reflectVec = viewDir.reflect(normal);
            reflectVec = reflectVec.normalize().lerp(normal, roughness * roughness);
            reflectVec = reflectVec.transformDirection(viewMatrix.inverse());
            var envMapColor = textureCubeUV(envMap, envMapRotation.multiply(reflectVec), roughness);
            return new FloatVector3(envMapColor.r, envMapColor.g, envMapColor.b).multiply(envMapIntensity);
        #else
            return new FloatVector3(0.0, 0.0, 0.0);
        #endif
        #else
            return new FloatVector3(0.0, 0.0, 0.0);
        #endif
    }

    #ifdef USE_ANISOTROPY
    public static function getIBLAnisotropyRadiance(viewDir:FloatVector3, normal:FloatVector3, roughness:Float, bitangent:FloatVector3, anisotropy:Float):FloatVector3 {
        #ifdef USE_ENVMAP
        #ifdef ENVMAP_TYPE_CUBE_UV
            var bentNormal = bitangent.cross(viewDir).normalize();
            bentNormal = bentNormal.cross(bitangent).normalize();
            bentNormal = bentNormal.lerp(normal, Math.pow(1.0 - anisotropy * (1.0 - roughness), 4));
            return getIBLRadiance(viewDir, bentNormal, roughness);
        #else
            return new FloatVector3(0.0, 0.0, 0.0);
        #endif
        #else
            return new FloatVector3(0.0, 0.0, 0.0);
        #endif
    }
    #endif
}