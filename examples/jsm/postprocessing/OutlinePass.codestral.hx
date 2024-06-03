import js.html.Three;
import js.html.Three.renderers.WebGLRenderer;
import js.html.Three.cameras.Camera;
import js.html.Three.cameras.PerspectiveCamera;
import js.html.Three.cameras.OrthographicCamera;
import js.html.Three.materials.Material;
import js.html.Three.materials.MeshDepthMaterial;
import js.html.Three.materials.ShaderMaterial;
import js.html.Three.materials.UniformsUtils;
import js.html.Three.scenes.Scene;
import js.html.Three.textures.Texture;
import js.html.Three.textures.WebGLRenderTarget;
import js.html.Three.core.Vector2;
import js.html.Three.core.Vector3;
import js.html.Three.core.Color;
import js.html.Three.core.Matrix4;
import js.html.Three.constants.Constants;
import js.html.Three.extras.objects.ImmediateRenderObject;
import js.html.Three.extras.core.ShapeUtils;

class OutlinePass extends Pass {
    public var renderScene:Scene;
    public var renderCamera:Camera;
    public var selectedObjects:Array<ImmediateRenderObject>;
    public var visibleEdgeColor:Color;
    public var hiddenEdgeColor:Color;
    public var edgeGlow:Float;
    public var usePatternTexture:Bool;
    public var edgeThickness:Float;
    public var edgeStrength:Float;
    public var downSampleRatio:Float;
    public var pulsePeriod:Float;

    public var _visibilityCache:haxe.ds.StringMap;

    // Rest of the class...

    static var BlurDirectionX:Vector2 = new Vector2(1.0, 0.0);
    static var BlurDirectionY:Vector2 = new Vector2(0.0, 1.0);
}