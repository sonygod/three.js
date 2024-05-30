class EnvmapVertex {
    public static var shaderCode:String = '
    #ifdef USE_ENVMAP

        #ifdef ENV_WORLDPOS

            vWorldPosition = worldPosition.xyz;

        #else

            var cameraToVertex:Vec3;

            if (isOrthographic) {

                cameraToVertex = normalize(vec3(-viewMatrix[0][2], -viewMatrix[1][2], -viewMatrix[2][2]));

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
    ';
}