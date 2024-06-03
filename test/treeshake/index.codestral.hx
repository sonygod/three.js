import away3d.cameras.PerspectiveLens;
import away3d.containers.View3D;
import away3d.entities.Mesh;
import away3d.materials.BitmapMaterial;
import away3d.materials.ColorMaterial;
import away3d.scenes.Scene3D;
import away3d.stages.Stage3D;
import away3d.textures.BitmapTexture;
import openfl.display.Sprite;

class ThreeJSExample {

    private var camera:PerspectiveLens;
    private var scene:Scene3D;
    private var renderer:Stage3D;

    public function new() {
        init();
    }

    private function init():Void {
        // Create a new 3D scene
        scene = new Scene3D();

        // Create a new perspective camera
        camera = new PerspectiveLens(70, Stage.width / Stage.height, 0.01, 10);
        camera.position.z = 5;

        // Create a new WebGL renderer
        renderer = new Stage3D(Stage.width, Stage.height);
        renderer.addChild(scene);
        renderer.addEventListener(Event.ENTER_FRAME, animation);

        // Add the renderer to the display list
        this.addChild(renderer);
    }

    private function animation(event:Event):Void {
        // Render the scene
        renderer.render(scene, camera);
    }
}