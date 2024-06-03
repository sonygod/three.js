class ShaderChunk_GradientMap_Fragment {
    var gradientMap: Texture;

    // Constructor
    function new() {}

    // Method to get gradient irradiance
    function getGradientIrradiance(normal: Vector3, lightDirection: Vector3): Vector3 {
        // Dot product of normal and lightDirection
        var dotNL: Float = normal.dot(lightDirection);
        var coord: Vector2 = new Vector2(dotNL * 0.5 + 0.5, 0.0);

        // Check if USE_GRADIENTMAP is defined
        #if USE_GRADIENTMAP
            // Return the texture value
            return new Vector3(gradientMap.getPixel(coord.x, coord.y).r, 0.0, 0.0);
        #else
            // Calculate fw
            var fw: Vector2 = new Vector2(Math.fwidth(coord.x) * 0.5, Math.fwidth(coord.y) * 0.5);
            // Mix two vectors based on coord.x
            return new Vector3(Math.mix(0.7, 1.0, Math.smoothstep(0.7 - fw.x, 0.7 + fw.x, coord.x)), 0.0, 0.0);
        #endif
    }
}