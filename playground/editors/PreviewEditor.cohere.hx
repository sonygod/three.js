import js.three.addons.controls.OrbitControls;
import js.three.addons.helpers.ViewHelper;
import js.flow.Element;
import js.flow.LabelElement;
import js.flow.SelectInput;
import js.three.nodes.MeshBasicNodeMaterial;
import js.three.PerspectiveCamera;
import js.three.Scene;
import js.three.Mesh;
import js.three.DoubleSide;
import js.three.SphereGeometry;
import js.three.BoxGeometry;
import js.three.PlaneGeometry;
import js.three.TorusKnotGeometry;
import js.three.addons.renderers.webgpu.WebGPURenderer;

class PreviewEditor {
    static var sceneDict:Map<String,Scene> = {};

    public function new() {
        var width = 300;
        var height = 300;
        super("Preview", null, width);

        var material = MeshBasicNodeMaterial();
        material.colorNode = vec4(0, 0, 0, 1);
        material.side = DoubleSide.DoubleSide;
        material.transparent = true;

        var previewElement = Element();
        previewElement.dom.style.paddingTop = "0";
        previewElement.dom.style.paddingBottom = "0";
        previewElement.dom.style.paddingLeft = "0";
        previewElement.dom.style.paddingRight = "14px";

        var sceneInput = SelectInput([
            { name : "Box", value : "box" },
            { name : "Sphere", value : "sphere" },
            { name : "Plane", value : "plane" },
            { name : "Sprite", value : "sprite" },
            { name : "Torus", value : "torus" }
        ], "box");

        var inputElement = setInputAestheticsFromType(LabelElement("Input"), "Color");
        inputElement.onConnect(function() {
            material.colorNode = inputElement.getLinkedObject() != null ? inputElement.getLinkedObject() : vec4(0, 0, 0, 1);
            material.dispose();
        }, true);

        var canvas = js.Browser.document.createElement("canvas");
        canvas.style.position = "absolute";
        previewElement.dom.appendChild(canvas);
        previewElement.setHeight(height);

        previewElement.dom.addEventListener("wheel", function(e:js.html.WheelEvent) e.stopPropagation());

        var renderer = WebGPURenderer({
            canvas : canvas,
            alpha : true,
            antialias : true
        });

        renderer.autoClear = false;
        renderer.setSize(width, height, true);
        renderer.setPixelRatio(js.Browser.window.devicePixelRatio);

        var camera = PerspectiveCamera(45, width / height, 0.1, 100);
        camera.aspect = width / height;
        camera.updateProjectionMatrix();
        camera.position.set(-2, 2, 2);
        camera.lookAt(0, 0, 0);

        var controls = OrbitControls(camera, previewElement.dom);
        controls.enableKeys = false;
        controls.update();

        var viewHelper = ViewHelper(camera, previewElement.dom);

        this.sceneInput = sceneInput;
        this.viewHelper = viewHelper;
        this.material = material;
        this.camera = camera;
        this.renderer = renderer;

        this.add(inputElement)
            .add(LabelElement("Object").add(sceneInput))
            .add(previewElement);
    }

    public function setEditor(editor) {
        super.setEditor(editor);
        this.updateAnimationRequest();
    }

    public function updateAnimationRequest() {
        if (this.editor != null) {
            js.Browser.window.requestAnimationFrame(function() this.update());
        }
    }

    public async function update() {
        var sceneName = this.sceneInput.getValue();
        var scene = PreviewEditor.getScene(sceneName);
        var mesh = scene.children[0] as Mesh;

        mesh.material = this.material;

        if (sceneName == "sprite") {
            mesh.lookAt(this.camera.position);
        }

        await this.renderer.clearAsync();
        await this.renderer.renderAsync(scene, this.camera);

        this.viewHelper.render(this.renderer);
    }

    static function getScene(name:String):Scene {
        var scene = PreviewEditor.sceneDict.get(name);

        if (scene == null) {
            scene = Scene();

            if (name == "box") {
                var box = Mesh(BoxGeometry(1.3, 1.3, 1.3));
                scene.add(box);
            } else if (name == "sphere") {
                var sphere = Mesh(SphereGeometry(1, 32, 16));
                scene.add(sphere);
            } else if (name == "plane" || name == "sprite") {
                var plane = Mesh(PlaneGeometry(2, 2));
                scene.add(plane);
            } else if (name == "torus") {
                var torus = Mesh(TorusKnotGeometry(0.7, 0.1, 100, 16));
                scene.add(torus);
            }

            PreviewEditor.sceneDict.set(name, scene);
        }

        return scene;
    }
}