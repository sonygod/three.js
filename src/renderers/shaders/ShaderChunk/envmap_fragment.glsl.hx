package renderers.shaders.ShaderChunk;

class EnvmapFragment {
    public function new() {}

    @glsl("
        #ifdef USE_ENVMAP

            #ifdef ENV_WORLDPOS

                var cameraToFrag:Vec3;

                if (isOrthographic) {
                    cameraToFrag = normalize(Vec3(-viewMatrix[0][2], -viewMatrix[1][2], -viewMatrix[2][2]));
                } else {
                    cameraToFrag = normalize(vWorldPosition - cameraPosition);
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

                var envColor:Vec4 = textureCube(envMap, envMapRotation * Vec3(flipEnvMap * reflectVec.x, reflectVec.yz));

            #else

                var envColor:Vec4 = Vec4(0.0, 0.0, 0.0, 0.0);

            #endif

            #ifdef ENVMAP_BLENDING_MULTIPLY

                outgoingLight = mix(outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity);

            #elif defined( ENVMAP_BLENDING_MIX )

                outgoingLight = mix(outgoingLight, envColor.xyz, specularStrength * reflectivity);

            #elif defined( ENVMAP_BLENDING_ADD )

                outgoingLight += envColor.xyz * specularStrength * reflectivity;

            #endif

        #endif
    ");
}