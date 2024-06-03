import hxwebgpu.*;
import hxwebgpu.wgsl.ast.WgslModule;
import hxwebgpu.wgsl.ast.WgslShaderStage;

class SSAOShader {
    public static function createShader(): WgslModule {
        return WgslModule.parse(
            'struct Uniforms {
                tNormal: texture_2d<f32>;
                tDepth: texture_2d<f32>;
                tNoise: texture_2d<f32>;
                kernel: array<vec3<f32>>;
                cameraNear: f32;
                cameraFar: f32;
                resolution: vec2<f32>;
                cameraProjectionMatrix: mat4x4<f32>;
                cameraInverseProjectionMatrix: mat4x4<f32>;
                kernelRadius: f32;
                minDistance: f32;
                maxDistance: f32;
            };

            @group(0) @binding(0) var<uniform> uniforms: Uniforms;

            @vertex
            fn vs_main(@location(0) position: vec4<f32>) -> @builtin(position) vec4<f32> {
                return uniforms.cameraProjectionMatrix * position;
            }

            fn getDepth(screenPosition: vec2<f32>): f32 {
                return textureLoad(uniforms.tDepth, screenPosition, 0).x;
            }

            // ... include other functions here ...

            @fragment
            fn fs_main(@location(0) position: vec4<f32>) -> @location(0) vec4<f32> {
                let depth = getDepth(position.xy / uniforms.resolution);

                // ... rest of the fragment shader code ...
            }'
        );
    }
}

// Repeat the same structure for SSAODepthShader and SSAOBlurShader