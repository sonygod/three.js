package three.renderers.shaders;

class EnvmapVertexShader {
    public function new() {}

    #if USE_ENVMAP

        #if ENV_WORLDPOS

            vWorldPosition = worldPosition.xyz;

        #else

            var cameraToVertex:Vec3;

            if (isOrthographic) {
                cameraToVertex = Vec3.normalize(new Vec3(-viewMatrix[0][2], -viewMatrix[1][2], -viewMatrix[2][2]));
            } else {
                cameraToVertex = Vec3.normalize(worldPosition.xyz - cameraPosition);
            }

            var worldNormal:Vec3 = inverseTransformDirection(transformedNormal, viewMatrix);

            #if ENVMAP_MODE_REFLECTION

                vReflect = reflect(cameraToVertex, worldNormal);

            #else

                vReflect = refract(cameraToVertex, worldNormal, refractionRatio);

            #end

        #end

    #end
}