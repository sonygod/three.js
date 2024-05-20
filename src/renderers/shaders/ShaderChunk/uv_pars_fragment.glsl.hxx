class Main {
    static function main() {
        var glslFragmentShader:String = /* glsl */`
            #if defined( USE_UV ) || defined( USE_ANISOTROPY )

                varying vec2 vUv;

            #endif
            // ... 其他的GLSL代码
        `;

        // 在这里使用glslFragmentShader
    }
}