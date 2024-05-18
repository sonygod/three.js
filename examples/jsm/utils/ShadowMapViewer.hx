package three.js.examples.jsm.utils;

import three.DoubleSide;
import three.LinearFilter;
import three.Mesh;
import three.MeshBasicMaterial;
import three.OrthographicCamera;
import three.PlaneGeometry;
import three.Scene;
import three.ShaderMaterial;
import three.Texture;
import three.UniformsUtils;

import shaders.UnpackDepthRGBAShader;

class ShadowMapViewer {
    public var enabled:Bool;
    public var size:Size;
    public var position:Position;
    private var scope:ShadowMapViewer;
    private var doRenderLabel:Bool;
    private var userAutoClearSetting:Bool;
    private var frame:Frame;
    private var camera:OrthographicCamera;
    private var scene:Scene;
    private var shader:UnpackDepthRGBAShader;
    private var uniforms:UniformsUtils;
    private var material:ShaderMaterial;
    private var mesh:Mesh;
    private var labelCanvas:js.html.CanvasElement;
    private var labelMesh:Mesh;
    private var light:Dynamic; // assumes light is of type DirectionalLight or SpotLight

    public function new(light:Dynamic) {
        scope = this;
        doRenderLabel = (light.name != null && light.name != "");
        userAutoClearSetting = true;

        frame = {
            x: 10,
            y: 10,
            width: 256,
            height: 256
        };

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
        var plane = new PlaneGeometry(frame.width, frame.height);
        mesh = new Mesh(plane, material);

        scene.add(mesh);

        if (doRenderLabel) {
            labelCanvas = js.Browser.document.createElement("canvas");
            var context = labelCanvas.getContext("2d");
            context.font = "Bold 20px Arial";

            var labelWidth = context.measureText(light.name).width;
            labelCanvas.width = labelWidth;
            labelCanvas.height = 25; // 25 to account for g, p, etc.

            context.font = "Bold 20px Arial";
            context.fillStyle = "rgba(255, 0, 0, 1)";
            context.fillText(light.name, 0, 20);

            var labelTexture = new Texture(labelCanvas);
            labelTexture.magFilter = LinearFilter;
            labelTexture.minFilter = LinearFilter;
            labelTexture.needsUpdate = true;

            var labelMaterial = new MeshBasicMaterial({
                map: labelTexture,
                side: DoubleSide
            });
            labelMaterial.transparent = true;

            var labelPlane = new PlaneGeometry(labelCanvas.width, labelCanvas.height);
            labelMesh = new Mesh(labelPlane, labelMaterial);

            scene.add(labelMesh);
        }

        enabled = true;

        size = {
            width: frame.width,
            height: frame.height,
            set: function(width, height) {
                this.width = width;
                this.height = height;

                mesh.scale.set(width / frame.width, height / frame.height, 1);

                resetPosition();
            }
        };

        position = {
            x: frame.x,
            y: frame.y,
            set: function(x, y) {
                this.x = x;
                this.y = y;

                var width = scope.size.width;
                var height = scope.size.height;

                mesh.position.set(-window.innerWidth / 2 + width / 2 + x, window.innerHeight / 2 - height / 2 - y, 0);

                if (doRenderLabel) labelMesh.position.set(mesh.position.x, mesh.position.y - scope.size.height / 2 + labelCanvas.height / 2, 0);
            }
        };

        resetPosition = function() {
            scope.position.set(scope.position.x, scope.position.y);
        };

        this.update();

        this.enabled = true;

        this.render = function(renderer) {
            if (this.enabled) {
                uniforms.tDiffuse.value = light.shadow.map.texture;

                userAutoClearSetting = renderer.autoClear;
                renderer.autoClear = false; // To allow render overlay
                renderer.clearDepth();
                renderer.render(scene, camera);
                renderer.autoClear = userAutoClearSetting; // Restore user's setting
            }
        };

        this.updateForWindowResize = function() {
            if (this.enabled) {
                camera.left = window.innerWidth / -2;
                camera.right = window.innerWidth / 2;
                camera.top = window.innerHeight / 2;
                camera.bottom = window.innerHeight / -2;
                camera.updateProjectionMatrix();

                this.update();
            }
        };

        this.update = function() {
            this.position.set(this.position.x, this.position.y);
            this.size.set(this.size.width, this.size.height);
        };
    }
}

typedef Size = {
    var width:Int;
    var height:Int;
    function set(width:Int, height:Int):Void;
}

typedef Position = {
    var x:Int;
    var y:Int;
    function set(x:Int, y:Int):Void;
}

typedef Frame = {
    var x:Int;
    var y:Int;
    var width:Int;
    var height:Int;
}