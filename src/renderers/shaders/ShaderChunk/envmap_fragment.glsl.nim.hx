package three.src.renderers.shaders.ShaderChunk;

class EnvmapFragment {
    #if use_envmap

        #if env_worldpos

            var cameraToFrag:Vec3;

            #if isOrthographic

                cameraToFrag = Vec3.normalize(Vec3.fromArray([-viewMatrix[0][2], -viewMatrix[1][2], -viewMatrix[2][2]]));

            #else

                cameraToFrag = Vec3.normalize(vWorldPosition - cameraPosition);

            #end

            // Transforming Normal Vectors with the Inverse Transformation
            var worldNormal:Vec3 = inverseTransformDirection(normal, viewMatrix);

            #if envmap_mode_reflection

                var reflectVec:Vec3 = reflect(cameraToFrag, worldNormal);

            #else

                var reflectVec:Vec3 = refract(cameraToFrag, worldNormal, refractionRatio);

            #end

        #else

            var reflectVec:Vec3 = vReflect;

        #end

        #if envmap_type_cube

            var envColor:Vec4 = textureCube(envMap, envMapRotation * Vec3.fromArray([flipEnvMap * reflectVec.x, reflectVec.y, reflectVec.z]));

        #else

            var envColor:Vec4 = Vec4.fromArray([0.0, 0.0, 0.0, 0.0]);

        #end

        #if envmap_blending_multiply

            outgoingLight = Vec3.mix(outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity);

        #elseif envmap_blending_mix

            outgoingLight = Vec3.mix(outgoingLight, envColor.xyz, specularStrength * reflectivity);

        #elseif envmap_blending_add

            outgoingLight += envColor.xyz * specularStrength * reflectivity;

        #end

    #end
}