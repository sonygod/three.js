class DigitalGlitch {
    public var uniforms:Map<String, Dynamic> = new Map<String, Dynamic>();
    public var vertexShader:String;
    public var fragmentShader:String;

    public function new() {
        uniforms["tDiffuse"] = { value: null };
        uniforms["tDisp"] = { value: null };
        uniforms["byp"] = { value: 0 };
        uniforms["amount"] = { value: 0.08 };
        uniforms["angle"] = { value: 0.02 };
        uniforms["seed"] = { value: 0.02 };
        uniforms["seed_x"] = { value: 0.02 };
        uniforms["seed_y"] = { value: 0.02 };
        uniforms["distortion_x"] = { value: 0.5 };
        uniforms["distortion_y"] = { value: 0.6 };
        uniforms["col_s"] = { value: 0.05 };

        vertexShader = "varying vec2 vUv; void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 ); }";

        fragmentShader = "uniform int byp; uniform sampler2D tDiffuse; uniform sampler2D tDisp; uniform float amount; uniform float angle; uniform float seed; uniform float seed_x; uniform float seed_y; uniform float distortion_x; uniform float distortion_y; uniform float col_s; varying vec2 vUv; float rand(vec2 co){ return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453); } void main() { if(byp<1) { /* rest of the code */ } else { gl_FragColor=texture2D (tDiffuse, vUv); } }";
    }
}

// You can use this class like this:
var digitalGlitch = new DigitalGlitch();