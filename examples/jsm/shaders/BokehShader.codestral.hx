import webgpu.shader.ShaderStage;
import webgpu.shader.ShaderModule;

class BokehShader {
    public static var name:String = "BokehShader";

    public static var defines:Dynamic = {
        'DEPTH_PACKING': 1,
        'PERSPECTIVE_CAMERA': 1,
    };

    public static var uniforms:Dynamic = {
        'tColor': { value: null },
        'tDepth': { value: null },
        'focus': { value: 1.0 },
        'aspect': { value: 1.0 },
        'aperture': { value: 0.025 },
        'maxblur': { value: 0.01 },
        'nearClip': { value: 1.0 },
        'farClip': { value: 1000.0 },
    };

    public static var vertexShader:ShaderModule = ShaderModule.fromWgsl(ShaderStage.VERTEX, `
        varying vec2<f32> vUv;

        @vertex
        fn main(@builtin(vertex_index) vertex_index: u32,
                @location(0) position: vec3<f32>,
                @location(1) uv: vec2<f32>) -> @builtin(position) vec4<f32> {
            vUv = uv;
            return projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    `);

    public static var fragmentShader:ShaderModule = ShaderModule.fromWgsl(ShaderStage.FRAGMENT, `
        #include <common>

        varying vec2<f32> vUv;

        @group(0) @binding(0) var tColor: texture_2d<f32>;
        @group(0) @binding(1) var tDepth: texture_2d<f32>;

        @group(1) @binding(0) var<uniform> focus: f32;
        @group(1) @binding(1) var<uniform> aspect: f32;
        @group(1) @binding(2) var<uniform> aperture: f32;
        @group(1) @binding(3) var<uniform> maxblur: f32;
        @group(1) @binding(4) var<uniform> nearClip: f32;
        @group(1) @binding(5) var<uniform> farClip: f32;

        #include <packing>

        fn getDepth(screenPosition: vec2<f32>) -> f32 {
            #if DEPTH_PACKING == 1
            return unpackRGBAToDepth(textureLoad(tDepth, vec2<i32>(screenPosition * vec2<f32>(textureDimensions(tDepth))), 0).r);
            #else
            return textureLoad(tDepth, vec2<i32>(screenPosition * vec2<f32>(textureDimensions(tDepth))), 0).r;
            #endif
        }

        fn getViewZ(depth: f32) -> f32 {
            #if PERSPECTIVE_CAMERA == 1
            return perspectiveDepthToViewZ(depth, nearClip, farClip);
            #else
            return orthographicDepthToViewZ(depth, nearClip, farClip);
            #endif
        }

        @fragment
        fn main(@location(0) fragColor: vec4<f32>) -> @location(0) vec4<f32> {
            let aspectcorrect = vec2<f32>(1.0, aspect);

            let viewZ = getViewZ(getDepth(vUv));

            let factor = (focus + viewZ);

            let dofblur = clamp(factor * aperture, -maxblur, maxblur) * aspectcorrect;

            let dofblur9 = dofblur * 0.9;
            let dofblur7 = dofblur * 0.7;
            let dofblur4 = dofblur * 0.4;

            var col = vec4<f32>(0.0);

            col += textureLoad(tColor, vec2<i32>(vUv * vec2<f32>(textureDimensions(tColor))), 0);
            col += textureLoad(tColor, vec2<i32>((vUv + vec2<f32>(0.0, 0.4) * dofblur) * vec2<f32>(textureDimensions(tColor))), 0);
            //... rest of the textureLoad lines ...

            return col / 41.0;
        }
    `);
}