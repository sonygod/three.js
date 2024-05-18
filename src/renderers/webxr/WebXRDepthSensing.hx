package renderers.webxr;

import three.geometries.PlaneGeometry;
import three.materials.ShaderMaterial;
import three.objects.Mesh;
import three.textures.Texture;

class WebXRDepthSensing {
    var texture:Texture;
    var mesh:Mesh;

    var depthNear:Float;
    var depthFar:Float;

    public function new() {}

    public function init(renderer:Dynamic, depthData:Dynamic, renderState:Dynamic) {
        if (texture == null) {
            var texture = new Texture();

            var texProps = renderer.properties.get(texture);
            texProps.__webglTexture = depthData.texture;

            if ((depthData.depthNear != renderState.depthNear) || (depthData.depthFar != renderState.depthFar)) {
                depthNear = depthData.depthNear;
                depthFar = depthData.depthFar;
            }

            this.texture = texture;
        }
    }

    public function render(renderer:Dynamic, cameraXR:Dynamic) {
        if (texture != null) {
            if (mesh == null) {
                var viewport = cameraXR.cameras[0].viewport;
                var material = new ShaderMaterial({
                    vertexShader: _occlusion_vertex,
                    fragmentShader: _occlusion_fragment,
                    uniforms: {
                        depthColor: { value: texture },
                        depthWidth: { value: viewport.z },
                        depthHeight: { value: viewport.w }
                    }
                });

                mesh = new Mesh(new PlaneGeometry(20, 20), material);
            }

            renderer.render(mesh, cameraXR);
        }
    }

    public function reset() {
        texture = null;
        mesh = null;
    }
}

@:keep
private var _occlusion_vertex:String = "
void main() {
    gl_Position = vec4( position, 1.0 );
}";

@:keep
private var _occlusion_fragment:String = "
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
}";