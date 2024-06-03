import three.geometries.PlaneGeometry;
import three.materials.ShaderMaterial;
import three.objects.Mesh;
import three.textures.Texture;

class WebXRDepthSensing {

    var texture:Texture;
    var mesh:Mesh;

    var depthNear:Float;
    var depthFar:Float;

    public function new() {
        this.texture = null;
        this.mesh = null;

        this.depthNear = 0;
        this.depthFar = 0;
    }

    public function init(renderer, depthData, renderState) {
        if (this.texture == null) {
            var texture = new Texture();

            var texProps = renderer.properties.get(texture);
            texProps.__webglTexture = depthData.texture;

            if (depthData.depthNear != renderState.depthNear || depthData.depthFar != renderState.depthFar) {
                this.depthNear = depthData.depthNear;
                this.depthFar = depthData.depthFar;
            }

            this.texture = texture;
        }
    }

    public function render(renderer, cameraXR) {
        if (this.texture != null) {
            if (this.mesh == null) {
                var viewport = cameraXR.cameras[0].viewport;
                var material = new ShaderMaterial({
                    vertexShader: _occlusion_vertex,
                    fragmentShader: _occlusion_fragment,
                    uniforms: [
                        { name: "depthColor", value: this.texture },
                        { name: "depthWidth", value: viewport.z },
                        { name: "depthHeight", value: viewport.w }
                    ]
                });

                this.mesh = new Mesh(new PlaneGeometry(20, 20), material);
            }

            renderer.render(this.mesh, cameraXR);
        }
    }

    public function reset() {
        this.texture = null;
        this.mesh = null;
    }
}