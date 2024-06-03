class UVVertexShader {
    function getShader():String {
        var shader = "";

        // Assuming that the USE_* flags are defined as constants or variables in your Haxe code
        if (USE_UV || USE_ANISOTROPY) {
            shader += "vUv = vec3( uv, 1 ).xy;\n";
        }

        if (USE_MAP) {
            shader += "vMapUv = ( mapTransform * vec3( MAP_UV, 1 ) ).xy;\n";
        }

        // Add similar conditions for other USE_* flags here...

        return shader;
    }
}