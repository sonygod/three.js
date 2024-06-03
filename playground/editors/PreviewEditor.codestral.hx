import three.nodes.MeshBasicNodeMaterial;
import three.nodes.vec4;
import three.PerspectiveCamera;
import three.Scene;
import three.Mesh;
import three.DoubleSide;
import three.SphereGeometry;
import three.BoxGeometry;
import three.PlaneGeometry;
import three.TorusKnotGeometry;

class PreviewEditor extends BaseNodeEditor {
    public var sceneInput:SelectInput;
    public var viewHelper:ViewHelper;
    public var material:MeshBasicNodeMaterial;
    public var camera:PerspectiveCamera;
    public var renderer:WebGPURenderer;

    public function new() {
        var width:Int = 300;
        var height:Int = 300;

        super("Preview", null, width);

        this.material = new MeshBasicNodeMaterial();
        this.material.colorNode = vec4(0, 0, 0, 1);
        this.material.side = DoubleSide;
        this.material.transparent = true;

        var previewElement:Element = new Element();
        previewElement.dom.style["padding-top"] = 0;
        previewElement.dom.style["padding-bottom"] = 0;
        previewElement.dom.style["padding-left"] = 0;
        previewElement.dom.style["padding-right"] = "14px";

        this.sceneInput = new SelectInput([
            {name: "Box", value: "box"},
            {name: "Sphere", value: "sphere"},
            {name: "Plane", value: "plane"},
            {name: "Sprite", value: "sprite"},
            {name: "Torus", value: "torus"}
        ], "box");

        var inputElement:LabelElement = setInputAestheticsFromType(new LabelElement("Input"), "Color").onConnect(function () {
            this.material.colorNode = inputElement.getLinkedObject() || vec4(0, 0, 0, 1);
            this.material.dispose();
        }, true);

        var canvas:HtmlElement = js.Browser.document.createElement("canvas");
        canvas.style.position = "absolute";
        previewElement.dom.append(canvas);
        previewElement.setHeight(height);

        previewElement.dom.addEventListener("wheel", function (e) {
            e.stopPropagation();
        });

        this.renderer = new WebGPURenderer({
            canvas: canvas,
            alpha: true,
            antialias: true
        });

        this.renderer.autoClear = false;
        this.renderer.setSize(width, height, true);
        this.renderer.setPixelRatio(js.Browser.window.devicePixelRatio);

        this.camera = new PerspectiveCamera(45, width / height, 0.1, 100);
        this.camera.aspect = width / height;
        this.camera.updateProjectionMatrix();
        this.camera.position.set(-2, 2, 2);
        this.camera.lookAt(0, 0, 0);

        var controls:OrbitControls = new OrbitControls(this.camera, previewElement.dom);
        controls.enableKeys = false;
        controls.update();

        this.viewHelper = new ViewHelper(this.camera, previewElement.dom);

        this.add(inputElement)
            .add(new LabelElement("Object").add(this.sceneInput))
            .add(previewElement);
    }

    public function setEditor(editor:Editor):Void {
        super.setEditor(editor);
        this.updateAnimationRequest();
    }

    public function updateAnimationRequest():Void {
        if (this.editor != null) {
            js.Browser.window.requestAnimationFrame(function () {
                this.update();
            });
        }
    }

    public async function update():Promise<Void> {
        this.updateAnimationRequest();

        var sceneName:String = this.sceneInput.getValue();

        var scene:Scene = getScene(sceneName);
        var mesh:Mesh = scene.children[0];

        mesh.material = this.material;

        if (sceneName == "sprite") {
            mesh.lookAt(this.camera.position);
        }

        await this.renderer.clearAsync();
        await this.renderer.renderAsync(scene, this.camera);

        this.viewHelper.render(this.renderer);
    }
}

var sceneDict:haxe.ds.StringMap<Scene> = new haxe.ds.StringMap();

function getScene(name:String):Scene {
    var scene:Scene = sceneDict.get(name);

    if (scene == null) {
        scene = new Scene();

        switch (name) {
            case "box":
                var box:Mesh = new Mesh(new BoxGeometry(1.3, 1.3, 1.3));
                scene.add(box);
                break;
            case "sphere":
                var sphere:Mesh = new Mesh(new SphereGeometry(1, 32, 16));
                scene.add(sphere);
                break;
            case "plane":
            case "sprite":
                var plane:Mesh = new Mesh(new PlaneGeometry(2, 2));
                scene.add(plane);
                break;
            case "torus":
                var torus:Mesh = new Mesh(new TorusKnotGeometry(0.7, 0.1, 100, 16));
                scene.add(torus);
                break;
        }

        sceneDict.set(name, scene);
    }

    return scene;
}