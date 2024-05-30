import three.geometries.PlaneGeometry;
import three.materials.ShaderMaterial;
import three.objects.Mesh;
import three.textures.Texture;
import three.renderers.WebGLRenderer;
import three.cameras.Camera;

class WebXRDepthSensing {
    public var texture:Texture;
    public var mesh:Mesh;
    public var depthNear:Float;
    public var depthFar:Float;

    public function new() {
        this.texture = null;
        this.mesh = null;
        this.depthNear = 0;
        this.depthFar = 0;
    }

    public function init(renderer:WebGLRenderer, depthData:Dynamic, renderState:Dynamic):Void {
        if (this.texture == null) {
            var texture = new Texture();
            var texProps = renderer.properties.get(texture);
            texProps.__webglTexture = depthData.texture;

            if ((depthData.depthNear != renderState.depthNear) || (depthData.depthFar != renderState.depthFar)) {
                this.depthNear = depthData.depthNear;
                this.depthFar = depthData.depthFar;
            }

            this.texture = texture;
        }
    }

    public function render(renderer:WebGLRenderer, cameraXR:Camera):Void {
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

    static var _occlusion_vertex = "
        void main() {
            gl_Position = vec4( position, 1.0 );
        }
    ";

    static var _occlusion_fragment = "
        uniform sampler2DArray depthColor;
        uniform float depthWidth;
        uniform float depthHeight;

        void main() {
            vec2 coord = vec2( gl_FragCoord.x / depthWidth, gl_FragCoord.y / depthHeight );

            if ( coord.x >= 1.0 ) {
                gl_FragDepth = texture( depthColor, vec3( coord.x - 1.0, coord.y, 1 ) ).r;
            } else {
                gl_FragDepth = texture( depthColor, vec3( coord.x, coord.y, 0 ) ).r;
            }
        }
    ";
}