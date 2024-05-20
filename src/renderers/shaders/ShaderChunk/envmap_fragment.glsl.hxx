class EnvmapFragment {
    public static var code:String =
        #if USE_ENVMAP
            #if ENV_WORLDPOS
                var cameraToFrag:Vec3;
                if (isOrthographic) {
                    cameraToFrag = Vec3.normalize(new Vec3(-viewMatrix[0][2], -viewMatrix[1][2], -viewMatrix[2][2]));
                } else {
                    cameraToFrag = Vec3.normalize(vWorldPosition - cameraPosition);
                }
                var worldNormal:Vec3 = inverseTransformDirection(normal, viewMatrix);
                #if ENVMAP_MODE_REFLECTION
                    var reflectVec:Vec3 = Vec3.reflect(cameraToFrag, worldNormal);
                #else
                    var reflectVec:Vec3 = Vec3.refract(cameraToFrag, worldNormal, refractionRatio);
                #end
            #else
                var reflectVec:Vec3 = vReflect;
            #end
            #if ENVMAP_TYPE_CUBE
                var envColor:Vec4 = textureCube(envMap, envMapRotation * Vec3.new(flipEnvMap * reflectVec.x, reflectVec.yz));
            #else
                var envColor:Vec4 = Vec4.new(0.0, 0.0, 0.0, 0.0);
            #end
            #if ENVMAP_BLENDING_MULTIPLY
                outgoingLight = Vec3.mix(outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity);
            #elseif ENVMAP_BLENDING_MIX
                outgoingLight = Vec3.mix(outgoingLight, envColor.xyz, specularStrength * reflectivity);
            #elseif ENVMAP_BLENDING_ADD
                outgoingLight += envColor.xyz * specularStrength * reflectivity;
            #end
        #end
    }
}