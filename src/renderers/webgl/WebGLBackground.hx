package renderers.webgl;

import three.constants.BackSide;
import three.constants.FrontSide;
import three.constants.CubeUVReflectionMapping;
import three.constants.SRGBTransfer;
import three.geometries.BoxGeometry;
import three.geometries.PlaneGeometry;
import three.materials.ShaderMaterial;
import three.math.Color;
import three.math.ColorManagement;
import three.math.Euler;
import three.math.Matrix4;
import three.objects.Mesh;
import three.shaders.ShaderLib;
import three.shaders.UniformsUtils;

class WebGLBackground {
    private var _rgb = { r: 0., b: 0., g: 0. };
    private var _e1:Euler = new Euler();
    private var _m1:Matrix4 = new Matrix4();

    private var clearColor:Color = new Color(0x000000);
    private var clearAlpha:Float = 1.;
    private var planeMesh:Mesh;
    private var boxMesh:Mesh;
    private var currentBackground:Dynamic;
    private var currentBackgroundVersion:Int = 0;
    private var currentTonemapping:Dynamic;

    public function new(renderer:Dynamic, cubemaps:Dynamic, cubeuvmaps:Dynamic, state:Dynamic, objects:Dynamic, alpha:Bool, premultipliedAlpha:Bool) {
        // ...
    }

    private function getBackground(scene:Dynamic):Dynamic {
        // ...
    }

    private function render(scene:Dynamic):Void {
        // ...
    }

    private function addToRenderList(renderList:Array<Dynamic>, scene:Dynamic):Void {
        // ...
    }

    private function setClear(color:Color, alpha:Float):Void {
        // ...
    }

    public function getClearColor():Color {
        return clearColor;
    }

    public function setClearColor(color:Color, alpha:Float = 1.):Void {
        clearColor.set(color);
        clearAlpha = alpha;
        setClear(clearColor, clearAlpha);
    }

    public function getClearAlpha():Float {
        return clearAlpha;
    }

    public function setClearAlpha(alpha:Float):Void {
        clearAlpha = alpha;
        setClear(clearColor, clearAlpha);
    }

    public function render():Void {
        render(null);
    }

    public function addToRenderList(renderList:Array<Dynamic>, scene:Dynamic):Void {
        addToRenderList(renderList, scene);
    }
}