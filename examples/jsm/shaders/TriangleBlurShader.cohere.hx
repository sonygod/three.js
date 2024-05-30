package math;

import js.three.Vector2;

class TriangleBlurShader {
    public static var name: String = "TriangleBlurShader";
    public static var uniforms: { [key: String]: { value: Dynamic }; } = {
        "texture": { value: null },
        "delta": { value: new Vector2(1.0, 1.0) }
    };
    public static var vertexShader: String = "
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    ";
    public static var fragmentShader: String = "
        #include <common>
        #define ITERATIONS 10.0
        uniform sampler2D texture;
        uniform vec2 delta;
        varying vec2 vUv;
        void main() {
            vec4 color = vec4(0.0);
            float total = 0.0;
            // randomize the lookup values to hide the fixed number of samples
            float offset = rand(vUv);
            for (float t = -ITERATIONS; t <= ITERATIONS; t++) {
                float percent = (t + offset - 0.5) / ITERATIONS;
                float weight = 1.0 - abs(percent);
                color += texture2D(texture, vUv + delta * percent) * weight;
                total += weight;
            }
            gl_FragColor = color / total;
        }
    ";
}