import three.math.Vector2;

class FXAAShader {
    public var name:String = "FXAAShader";
    public var uniforms:Map<String, Dynamic> = new Map<String, Dynamic>();
    public var vertexShader:String;
    public var fragmentShader:String;

    public function new() {
        this.uniforms["tDiffuse"] = {value: null};
        this.uniforms["resolution"] = {value: new Vector2(1 / 1024, 1 / 512)};

        this.vertexShader = `
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }
        `;

        this.fragmentShader = `
            precision highp float;

            uniform sampler2D tDiffuse;
            uniform vec2 resolution;

            varying vec2 vUv;

            // FXAA 3.11 implementation by NVIDIA, ported to WebGL by Agost Biro (biro@archilogic.com)

            // ... rest of the fragment shader code ...

        `;
    }
}