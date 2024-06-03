import three.math.Matrix4;
import three.math.Vector2;

class SSRShader {
    public static var name:String = "SSRShader";
    public static var defines:Map<String, Bool> = [
        "MAX_STEP": 0,
        "PERSPECTIVE_CAMERA": true,
        "DISTANCE_ATTENUATION": true,
        "FRESNEL": true,
        "INFINITE_THICK": false,
        "SELECTIVE": false,
    ];
    public static var uniforms:Map<String, Dynamic> = [
        "tDiffuse": { value: null },
        "tNormal": { value: null },
        "tMetalness": { value: null },
        "tDepth": { value: null },
        "cameraNear": { value: null },
        "cameraFar": { value: null },
        "resolution": { value: new Vector2() },
        "cameraProjectionMatrix": { value: new Matrix4() },
        "cameraInverseProjectionMatrix": { value: new Matrix4() },
        "opacity": { value: .5 },
        "maxDistance": { value: 180 },
        "cameraRange": { value: 0 },
        "thickness": { value: .018 }
    ];
    public static var vertexShader:String = "..."; // Your vertex shader code here
    public static var fragmentShader:String = "..."; // Your fragment shader code here
}

class SSRDepthShader {
    // Similar to SSRShader, define name, defines, uniforms, vertexShader, and fragmentShader
}

class SSRBlurShader {
    // Similar to SSRShader, define name, uniforms, vertexShader, and fragmentShader
}