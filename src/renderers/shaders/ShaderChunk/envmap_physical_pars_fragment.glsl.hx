package three.renderers.shaders;

import haxe.ds.StringMap;

class EnvmapPhysicalParsFragment {
    public function new() {}

    public function getIBLIrradiance(normal:Vec3):Vec3 {
        #if USE_ENVMAP
            #if ENVMAP_TYPE_CUBE_UV
                var worldNormal:Vec3 = inverseTransformDirection(normal, viewMatrix);
                var envMapColor:Vec4 = textureCubeUV(envMap, envMapRotation * worldNormal, 1.0);
                return PI * envMapColor.rgb * envMapIntensity;
            #else
                return new Vec3(0.0, 0.0, 0.0);
            #end
        #else
            return new Vec3(0.0, 0.0, 0.0);
        #end
    }

    public function getIBLRadiance(viewDir:Vec3, normal:Vec3, roughness:Float):Vec3 {
        #if USE_ENVMAP
            #if ENVMAP_TYPE_CUBE_UV
                var reflectVec:Vec3 = reflect(-viewDir, normal);
                reflectVec = normalize(mix(reflectVec, normal, roughness * roughness));
                reflectVec = inverseTransformDirection(reflectVec, viewMatrix);
                var envMapColor:Vec4 = textureCubeUV(envMap, envMapRotation * reflectVec, roughness);
                return envMapColor.rgb * envMapIntensity;
            #else
                return new Vec3(0.0, 0.0, 0.0);
            #end
        #else
            return new Vec3(0.0, 0.0, 0.0);
        #end
    }

    #if USE_ANISOTROPY
    public function getIBLAnisotropyRadiance(viewDir:Vec3, normal:Vec3, roughness:Float, bitangent:Vec3, anisotropy:Float):Vec3 {
        #if ENVMAP_TYPE_CUBE_UV
            var bentNormal:Vec3 = cross(bitangent, viewDir);
            bentNormal = normalize(cross(bentNormal, bitangent));
            bentNormal = normalize(mix(bentNormal, normal, pow2(pow2(1.0 - anisotropy * (1.0 - roughness)))));
            return getIBLRadiance(viewDir, bentNormal, roughness);
        #else
            return new Vec3(0.0, 0.0, 0.0);
        #end
    }
    #end
}