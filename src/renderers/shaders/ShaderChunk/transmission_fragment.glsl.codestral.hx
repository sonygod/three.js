@:meta(ShaderChunk("transmission_fragment.glsl"))
class TransmissionFragment {
    public static function getCode():String {
        return """
        #ifdef USE_TRANSMISSION

            material.transmission = transmission;
            material.transmissionAlpha = 1.0;
            material.thickness = thickness;
            material.attenuationDistance = attenuationDistance;
            material.attenuationColor = attenuationColor;

            #ifdef USE_TRANSMISSIONMAP

                material.transmission *= texture2D( transmissionMap, vTransmissionMapUv ).r;

            #endif

            #ifdef USE_THICKNESSMAP

                material.thickness *= texture2D( thicknessMap, vThicknessMapUv ).g;

            #endif

            var pos:Vec3 = vWorldPosition;
            var v:Vec3 = normalize( cameraPosition - pos );
            var n:Vec3 = inverseTransformDirection( normal, viewMatrix );

            var transmitted:Vec4 = getIBLVolumeRefraction(
                n, v, material.roughness, material.diffuseColor, material.specularColor, material.specularF90,
                pos, modelMatrix, viewMatrix, projectionMatrix, material.dispersion, material.ior, material.thickness,
                material.attenuationColor, material.attenuationDistance );

            material.transmissionAlpha = mix( material.transmissionAlpha, transmitted.a, material.transmission );

            totalDiffuse = mix( totalDiffuse, transmitted.rgb, material.transmission );

        #endif
        """;
    }
}