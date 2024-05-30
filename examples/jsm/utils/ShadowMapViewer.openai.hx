package three.js.utils;

import three.jsgeom.PlaneGeometry;
import three.jsgeom.OrthographicCamera;
import three.jsgeom.Mesh;
import three.jsgeom.MeshBasicMaterial;
import three.jsgeom.Scene;
import three.jsgeom.ShaderMaterial;
import three.jsgeom.Texture;
import three.jsUtils.UnpackDepthRGBAShader;
import three.jsUtils.UniformsUtils;

class ShadowMapViewer {
    // Holds the initial position and dimension of the HUD
    private var frame: { x: Int, y: Int, width: Int, height: Int } = { x: 10, y: 10, width: 256, height: 256 };

    private var camera: OrthographicCamera;
    private var scene: Scene;
    private var shader: UnpackDepthRGBAShader;
    private var uniforms: Dynamic;
    private var material: ShaderMaterial;
    private var plane: PlaneGeometry;
    private var mesh: Mesh;
    private var light: Dynamic;

    public var enabled: Bool = true;

    public var size: { width: Int, height: Int, set: Void->Void } = {
        width: frame.width,
        height: frame.height,
        set: function(w, h) {
            this.width = w;
            this.height = h;
            mesh.scale.set(w / frame.width, h / frame.height, 1);
        }
    };

    public var position: { x: Int, y: Int, set: Void->Void } = {
        x: frame.x,
        y: frame.y,
        set: function(x, y) {
            this.x = x;
            this.y = y;
            var width = size.width;
            var height = size.height;
            mesh.position.set(-window.innerWidth / 2 + width / 2 + x, window.innerHeight / 2 - height / 2 - y, 0);
        }
    };

    public function new(light: Dynamic) {
        this.light = light;

        camera = new OrthographicCamera(-window.innerWidth / 2, window.innerWidth / 2, window.innerHeight / 2, window.innerHeight / -2, 1, 10);
        camera.position.set(0, 0, 2);

        scene = new Scene();

        shader = UnpackDepthRGBAShader;

        uniforms = UniformsUtils.clone(shader.uniforms);
        material = new ShaderMaterial({
            uniforms: uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        });
        plane = new PlaneGeometry(frame.width, frame.height);
        mesh = new Mesh(plane, material);

        scene.add(mesh);

        if (light.name != null && light.name != '') {
            var labelCanvas = js.Browser.document.createElement('canvas');
            var context = labelCanvas.getContext('2d');
            context.font = 'Bold 20px Arial';
            var labelWidth = context.measureText(light.name).width;
            labelCanvas.width = labelWidth;
            labelCanvas.height = 25;
            context.font = 'Bold 20px Arial';
            context.fillStyle = 'rgba( 255, 0, 0, 1 )';
            context.fillText(light.name, 0, 20);

            var labelTexture = new Texture(labelCanvas);
            labelTexture.magFilter = LinearFilter;
            labelTexture.minFilter = LinearFilter;
            labelTexture.needsUpdate = true;

            var labelMaterial = new MeshBasicMaterial({ map: labelTexture, side: DoubleSide });
            labelMaterial.transparent = true;

            var labelPlane = new PlaneGeometry(labelCanvas.width, labelCanvas.height);
            var labelMesh = new Mesh(labelPlane, labelMaterial);

            scene.add(labelMesh);
        }
    }

    public function render(renderer: Dynamic) {
        if (enabled) {
            uniforms.tDiffuse.value = light.shadow.map.texture;
            var userAutoClearSetting = renderer.autoClear;
            renderer.autoClear = false;
            renderer.clearDepth();
            renderer.render(scene, camera);
            renderer.autoClear = userAutoClearSetting;
        }
    }

    public function updateForWindowResize() {
        if (enabled) {
            camera.left = window.innerWidth / -2;
            camera.right = window.innerWidth / 2;
            camera.top = window.innerHeight / 2;
            camera.bottom = window.innerHeight / -2;
            camera.updateProjectionMatrix();
            update();
        }
    }

    public function update() {
        position.set(position.x, position.y);
        size.set(size.width, size.height);
    }
}