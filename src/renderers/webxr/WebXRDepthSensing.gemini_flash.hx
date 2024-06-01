import three.Mesh;
import three.PlaneGeometry;
import three.ShaderMaterial;
import three.Texture;
import three.WebGLProperties;
import three.WebGLRenderer;
import three.WebXRManager;

class WebXRDepthSensing {

	public var texture:Texture;
	public var mesh:Mesh;

	public var depthNear:Float;
	public var depthFar:Float;

	static var _occlusion_vertex:String = "
		void main() {
			gl_Position = vec4( position, 1.0 );
		}
	";

	static var _occlusion_fragment:String = "
		uniform sampler2DArray depthColor;
		uniform float depthWidth;
		uniform float depthHeight;
		
		void main() {
			vec2 coord = vec2( gl_FragCoord.x / depthWidth, gl_FragCoord.y / depthHeight );
		
			if ( coord.x >= 1.0 ) {
				gl_FragDepth = texture( depthColor, vec3( coord.x - 1.0, coord.y, 1.0 ) ).r;
			} else {
				gl_FragDepth = texture( depthColor, vec3( coord.x, coord.y, 0.0 ) ).r;
			}
		}
	";

	public function new() {
		this.texture = null;
		this.mesh = null;
		this.depthNear = 0;
		this.depthFar = 0;
	}

	public function init(renderer:WebGLRenderer, depthData:{ texture:Dynamic, depthNear:Float, depthFar:Float }, renderState:{ depthNear:Float, depthFar:Float }):Void {
		if (this.texture == null) {
			var texture = new Texture();

			// Accessing WebGLTexture directly is discouraged in Three.js and not directly possible in Haxe/Three.
			// Instead, you should update the texture data using Three.js methods.
			// For example, if you have a DataTexture, you can update its data using:
			// texture.image.data = depthData.texture.image.data;
			// texture.needsUpdate = true;
			
			var texProps:WebGLProperties = untyped renderer.properties.get(texture);
			Reflect.setProperty(texProps, "__webglTexture", depthData.texture);

			if (depthData.depthNear != renderState.depthNear || depthData.depthFar != renderState.depthFar) {
				this.depthNear = depthData.depthNear;
				this.depthFar = depthData.depthFar;
			}

			this.texture = texture;
		}
	}

	public function render(renderer:WebGLRenderer, cameraXR:WebXRManager):Void {
		if (this.texture != null) {
			if (this.mesh == null) {
				var viewport = cameraXR.cameras[0].viewport;
				var material = new ShaderMaterial({
					vertexShader: _occlusion_vertex,
					fragmentShader: _occlusion_fragment,
					uniforms: {
						depthColor: { value: this.texture },
						depthWidth: { value: viewport.z },
						depthHeight: { value: viewport.w }
					}
				});

				this.mesh = new Mesh(new PlaneGeometry(20, 20), material);
			}

			renderer.render(this.mesh, cameraXR);
		}
	}

	public function reset():Void {
		this.texture = null;
		this.mesh = null;
	}
}