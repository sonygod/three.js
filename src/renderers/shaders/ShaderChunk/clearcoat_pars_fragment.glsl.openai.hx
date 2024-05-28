@:glsl(
    ifdef USE_CLEARCOATMAP {
        uniform sampler2D clearcoatMap;
    }

    ifdef USE_CLEARCOAT_NORMALMAP {
        uniform sampler2D clearcoatNormalMap;
        uniform vec2 clearcoatNormalScale;
    }

    ifdef USE_CLEARCOAT_ROUGHNESSMAP {
        uniform sampler2D clearcoatRoughnessMap;
    }
)