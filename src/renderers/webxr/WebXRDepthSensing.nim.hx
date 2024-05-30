import three.geometries.PlaneGeometry;
import three.materials.ShaderMaterial;
import three.objects.Mesh;
import three.textures.Texture;

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

    public function init(renderer:Dynamic, depthData:Dynamic, renderState:Dynamic) {
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

    public function render(renderer:Dynamic, cameraXR:Dynamic) {
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

    public function reset() {
        this.texture = null;
        this.mesh = null;
    }

}

@:build(macro.Library.add("three.js"))
extern class three {
    @:native("THREE.PlaneGeometry")
    public static var PlaneGeometry:PlaneGeometry;
    @:native("THREE.ShaderMaterial")
    public static var ShaderMaterial:ShaderMaterial;
    @:native("THREE.Mesh")
    public static var Mesh:Mesh;
    @:native("THREE.Texture")
    public static var Texture:Texture;
}

@:build(macro.Library.add("three.js/src/geometries/PlaneGeometry.js"))
@:build(macro.Library.add("three.js/src/materials/ShaderMaterial.js"))
@:build(macro.Library.add("three.js/src/objects/Mesh.js"))
@:build(macro.Library.add("three.js/src/textures/Texture.js"))
@:build(macro.Library.add("three.js/src/renderers/webxr/WebXRDepthSensing.js"))