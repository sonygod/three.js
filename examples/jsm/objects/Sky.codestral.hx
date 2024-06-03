import js.html.Window;
import js.Boot;

@:native("three")
external class Three {
    var BackSide: Dynamic;
    var BoxGeometry: Class<BoxGeometry>;
    var Mesh: Class<Mesh>;
    var ShaderMaterial: Class<ShaderMaterial>;
    var UniformsUtils: UniformsUtils;
    var Vector3: Class<Vector3>;
}

@:native
class Sky extends Mesh {
    public function new() {
        super();

        var shader = Sky.SkyShader;

        var material = new ShaderMaterial({
            name: shader.name,
            uniforms: UniformsUtils.clone(shader.uniforms),
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            side: Three.BackSide,
            depthWrite: false
        });

        this.constructor(new Three.BoxGeometry(1, 1, 1), material);
        this.isSky = true;
    }
}

@:native
class SkyShader {
    public static var name: String = "SkyShader";

    public static var uniforms: Dynamic = {
        'turbidity': { value: 2 },
        'rayleigh': { value: 1 },
        'mieCoefficient': { value: 0.005 },
        'mieDirectionalG': { value: 0.8 },
        'sunPosition': { value: new Three.Vector3() },
        'up': { value: new Three.Vector3(0, 1, 0) }
    };

    public static var vertexShader: String = /* glsl */`
        // Vertex shader code here
    `;

    public static var fragmentShader: String = /* glsl */`
        // Fragment shader code here
    `;
}

class Main {
    public static function main() {
        // Your main function code here
    }
}