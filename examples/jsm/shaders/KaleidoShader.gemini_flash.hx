import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.geom.Vector3D;

class KaleidoShader extends Shader {

	public static var name:String = "KaleidoShader";

	public var tDiffuse:ShaderInput;
	public var sides:ShaderInput;
	public var angle:ShaderInput;

	public function new() {
		super(vertexShader, fragmentShader);

		tDiffuse = new ShaderInput(ShaderParameter.TEXTURE2D, "tDiffuse");
		sides = new ShaderInput(ShaderParameter.FLOAT, "sides");
		angle = new ShaderInput(ShaderParameter.FLOAT, "angle");

		this.addInput(tDiffuse);
		this.addInput(sides);
		this.addInput(angle);

		sides.value = 6.0;
		angle.value = 0.0;
	}

	static var vertexShader:String = """
		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}
	""";

	static var fragmentShader:String = """
		uniform sampler2D tDiffuse;
		uniform float sides;
		uniform float angle;

		varying vec2 vUv;

		void main() {

			vec2 p = vUv - 0.5;
			float r = length(p);
			float a = atan(p.y, p.x) + angle;
			float tau = 2. * 3.1416 ;
			a = mod(a, tau/sides);
			a = abs(a - tau/sides/2.) ;
			p = r * vec2(cos(a), sin(a));
			vec4 color = texture2D(tDiffuse, p + 0.5);
			gl_FragColor = color;

		}
	""";

}


**Explanation:**

1. **Class Definition:** We create a `KaleidoShader` class that extends the `Shader` class from OpenFL.
2. **Input Properties:** We define properties `tDiffuse`, `sides`, and `angle` as `ShaderInput` objects. These represent the inputs to the shader.
3. **Constructor:** In the constructor, we initialize the inputs and set default values for `sides` and `angle`.
4. **Vertex Shader:** The `vertexShader` remains largely the same, only the `varying` declaration is needed.
5. **Fragment Shader:** The `fragmentShader` is also largely the same. We access the shader inputs using their names (e.g., `tDiffuse`, `sides`, `angle`).

**Usage:**

1. **Create a KaleidoShader instance:**
   
   var shader:KaleidoShader = new KaleidoShader();
   

2. **Set the input values:**
   
   shader.tDiffuse.value = texture; // Set the texture input
   shader.sides.value = 8.0; // Set the number of reflections
   shader.angle.value = Math.PI / 4; // Set the initial angle
   

3. **Apply the shader to a display object:**
   
   mySprite.shader = shader;