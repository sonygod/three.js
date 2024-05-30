package;

import js.three.DoubleSide;
import js.three.LinearFilter;
import js.three.Mesh;
import js.three.MeshBasicMaterial;
import js.three.OrthographicCamera;
import js.three.PlaneGeometry;
import js.three.Scene;
import js.three.ShaderMaterial;
import js.three.Texture;
import js.three.UniformsUtils;

class ShadowMapViewer {
    public var enabled:Bool;
    public var size:ShadowMapViewerSize;
    public var position:ShadowMapViewerPosition;

    private var scope:ShadowMapViewer;
    private var doRenderLabel:Bool;
    private var userAutoClearSetting:Bool;
    private var frame:ShadowMapViewerFrame;
    private var camera:OrthographicCamera;
    private var scene:Scene;
    private var shader:UnpackDepthRGBAShader;
    private var uniforms:ShaderMaterialUniforms;
    private var material:ShaderMaterial;
    private var plane:PlaneGeometry;
    private var mesh:Mesh;
    private var labelCanvas:HTMLCanvasElement;
    private var labelMesh:Mesh;
    private var light:Dynamic;

    public function new(light:Dynamic) {
        scope = this;
        doRenderLabel = light.name != null && light.name != "";
        userAutoClearSetting = null;

        frame = { x: 10, y: 10, width: 256, height: 256 };

        camera = new OrthographicCamera(Std.int(Window.innerWidth / -2), Std.int(Window.innerWidth / 2), Std.int(Window.innerHeight / 2), Std.int(Window.innerHeight / -2), 1, 10);
        camera.position.set(0, 0, 2);
        scene = new Scene();

        shader = new UnpackDepthRGBAShader();

        uniforms = UniformsUtils.clone(shader.uniforms);
        material = new ShaderMaterial({ uniforms: uniforms, vertexShader: shader.vertexShader, fragmentShader: shader.fragmentShader });
        plane = new PlaneGeometry(frame.width, frame.height);
        mesh = new Mesh(plane, material);

        scene.add(mesh);

        if (doRenderLabel) {
            labelCanvas = window.document.createElement("canvas");
            var context = labelCanvas.getContext2d();
            context.font = "Bold 20px Arial";

            var labelWidth = context.measureText(light.name).width;
            labelCanvas.width = Std.int(labelWidth);
            labelCanvas.height = 25; // 25 to account for g, p, etc.

            context.font = "Bold 20px Arial";
            context.fillStyle = "rgba( 255, 0, 0, 1 )";
            context.fillText(light.name, 0, 20);

            var labelTexture = new Texture(labelCanvas);
            labelTexture.magFilter = LinearFilter.Linear;
            labelTexture.minFilter = LinearFilter.Linear;
            labelTexture.needsUpdate = true;

            var labelMaterial = new MeshBasicMaterial({ map: labelTexture, side: DoubleSide.DoubleSide });
            labelMaterial.transparent = true;

            var labelPlane = new PlaneGeometry(labelCanvas.width, labelCanvas.height);
            labelMesh = new Mesh(labelPlane, labelMaterial);

            scene.add(labelMesh);
        }

        function resetPosition() {
            scope.position.set(scope.position.x, scope.position.y);
        }

        enabled = true;
        size = { width: frame.width, height: frame.height, set: $set_size };
        position = { x: frame.x, y: frame.y, set: $set_position };
    }

    public function render(renderer:Dynamic) {
        if (enabled) {
            uniforms.tDiffuse.value = light.shadow.map.texture;

            userAutoClearSetting = renderer.autoClear;
            renderer.autoClear = false; // To allow render overlay
            renderer.clearDepth();
            renderer.render(scene, camera);
            renderer.autoClear = userAutoClearSetting; // Restore user's setting
        }
    }

    public function updateForWindowResize() {
        if (enabled) {
            camera.left = Std.int(Window.innerWidth / -2);
            camera.right = Std.int(Window.innerWidth / 2);
            camera.top = Std.int(Window.innerHeight / 2);
            camera.bottom = Std.int(Window.innerHeight / -2);
            camera.updateProjectionMatrix();

            update();
        }
    }

    public function update() {
        position.set(position.x, position.y);
        size.set(size.width, size.height);
    }

    private function $set_size(width:Int, height:Int) {
        this.width = width;
        this.height = height;

        mesh.scale.set(width / frame.width, height / frame.height, 1);

        // Reset the position as it is off when we scale stuff
        resetPosition();
    }

    private function $set_position(x:Int, y:Int) {
        this.x = x;
        this.y = y;

        var width = size.width;
        var height = size.height;

        mesh.position.set(-Std.int(Window.innerWidth / 2) + width / 2 + x, Std.int(Window.innerHeight / 2) - height / 2 - y, 0);

        if (doRenderLabel) {
            labelMesh.position.set(mesh.position.x, mesh.position.y - size.height / 2 + labelCanvas.height / 2, 0);
        }
    }
}

class ShadowMapViewerFrame {
    public var x:Int;
    public var y:Int;
    public var width:Int;
    public var height:Int;
}

class ShadowMapViewerSize {
    public var width:Int;
    public var height:Int;
    public function set(width:Int, height:Int):Void;
}

class ShadowMapViewerPosition {
    public var x:Int;
    public var y:Int;
    public function set(x:Int, y:Int):Void;
}

class UnpackDepthRGBAShader {
    public var uniforms:ShaderMaterialUniforms;
    public var vertexShader:String;
    public var fragmentShader:String;
}

class ShaderMaterialUniforms {
}