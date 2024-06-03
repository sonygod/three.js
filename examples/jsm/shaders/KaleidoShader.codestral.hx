class KaleidoShader {
    public static var name:String = "KaleidoShader";

    public static var uniforms:haxe.ds.StringMap = new haxe.ds.StringMap();
    static {
        uniforms.set("tDiffuse", { value : null });
        uniforms.set("sides", { value : 6.0 });
        uniforms.set("angle", { value : 0.0 });
    }

    public static var vertexShader:String = "varying vec2 vUv;

		void main() {
			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
		}";

    public static var fragmentShader:String = "uniform sampler2D tDiffuse;
		uniform float sides;
		uniform float angle;

		varying vec2 vUv;

		void main() {
			vec2 p = vUv - 0.5;
			float r = length(p);
			float a = atan(p.y, p.x) + angle;
			float tau = 2. * 3.1416 ;
			a = mod(a, tau/sides);
			a = abs(a - tau/sides/2.);
			p = r * vec2(cos(a), sin(a));
			vec4 color = texture2D(tDiffuse, p + 0.5);
			gl_FragColor = color;
		}";
}