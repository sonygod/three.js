class ShaderChunk {
    static var transmission_fragment:String =
        #if USE_TRANSMISSION

            material.transmission = transmission;
            material.transmissionAlpha = 1.0;
            material.thickness = thickness;
            material.attenuationDistance = attenuationDistance;
            material.attenuationColor = attenuationColor;

            #if USE_TRANSMISSIONMAP

                material.transmission *= texture2D( transmissionMap, vTransmissionMapUv ).r;

            #end

            #if USE_THICKNESSMAP

                material.thickness *= texture2D( thicknessMap, vThicknessMapUv ).g;

            #end

            var pos = vWorldPosition;
            var v = normalize( cameraPosition - pos );
            var n = inverseTransformDirection( normal, viewMatrix );

            var transmitted = getIBLVolumeRefraction(
                n, v, material.roughness, material.diffuseColor, material.specularColor, material.specularF90,
                pos, modelMatrix, viewMatrix, projectionMatrix, material.dispersion, material.ior, material.thickness,
                material.attenuationColor, material.attenuationDistance );

            material.transmissionAlpha = mix( material.transmissionAlpha, transmitted.a, material.transmission );

            totalDiffuse = mix( totalDiffuse, transmitted.rgb, material.transmission );

        #end
    ;
}