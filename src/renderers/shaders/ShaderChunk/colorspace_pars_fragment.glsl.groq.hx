package three.renderers.shaders;

@:glsl(
    "vec4 LinearSRGBToLinearDisplayP3(vec4 value) {
        return vec4(value.rgb * mat3(
            vec3(0.8224621, 0.177538, 0.0),
            vec3(0.0331941, 0.9668058, 0.0),
            vec3(0.0170827, 0.0723974, 0.9105199)
        ), value.a);
    }

    vec4 LinearDisplayP3ToLinearSRGB(vec4 value) {
        return vec4(value.rgb * mat3(
            vec3(1.2249401, -0.2249404, 0.0),
            vec3(-0.0420569, 1.0420571, 0.0),
            vec3(-0.0196376, -0.0786361, 1.0982735)
        ), value.a);
    }

    vec4 LinearTransferOETF(vec4 value) {
        return value;
    }

    vec4 sRGBTransferOETF(vec4 value) {
        return vec4(mix(pow(value.rgb, vec3(0.41666)) * 1.055 - vec3(0.055), value.rgb * 12.92, lessThanEqual(value.rgb, vec3(0.0031308))), value.a);
    }

    // @deprecated, r156
    vec4 LinearToLinear(vec4 value) {
        return value;
    }

    // @deprecated, r156
    vec4 LinearTosRGB(vec4 value) {
        return sRGBTransferOETF(value);
    }
")
class ShaderChunk {}