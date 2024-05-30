import three.Box3;
import three.MathUtils;
import three.MeshLambertMaterial;
import three.Object3D;
import three.TextureLoader;
import three.UVMapping;
import three.SRGBColorSpace;
import MD2Loader;
import MorphBlendMesh;

class MD2CharacterComplex {

    var scale:Float;
    var animationFPS:Int;
    var transitionFrames:Int;
    var maxSpeed:Float;
    var maxReverseSpeed:Float;
    var frontAcceleration:Float;
    var backAcceleration:Float;
    var frontDecceleration:Float;
    var angularSpeed:Float;
    var root:Object3D;
    var meshBody:MorphBlendMesh;
    var meshWeapon:MorphBlendMesh;
    var controls:Dynamic;
    var skinsBody:Array<Texture>;
    var skinsWeapon:Array<Texture>;
    var weapons:Array<MorphBlendMesh>;
    var currentSkin:Dynamic;
    var onLoadComplete:Dynamic->Void;
    var meshes:Array<MorphBlendMesh>;
    var animations:Dynamic;
    var loadCounter:Int;
    var speed:Float;
    var bodyOrientation:Float;
    var walkSpeed:Float;
    var crouchSpeed:Float;
    var activeAnimation:Dynamic;
    var oldAnimation:Dynamic;
    var blendCounter:Int;

    public function new() {
        // ...
    }

    // ...

    public function enableShadows(enable:Bool):Void {
        // ...
    }

    // ...

    public function setVisible(enable:Bool):Void {
        // ...
    }

    // ...

    public function shareParts(original:Dynamic):Void {
        // ...
    }

    // ...

    public function loadParts(config:Dynamic):Void {
        // ...
    }

    // ...

    public function setPlaybackRate(rate:Float):Void {
        // ...
    }

    // ...

    public function setWireframe(wireframeEnabled:Bool):Void {
        // ...
    }

    // ...

    public function setSkin(index:Int):Void {
        // ...
    }

    // ...

    public function setWeapon(index:Int):Void {
        // ...
    }

    // ...

    public function setAnimation(animationName:String):Void {
        // ...
    }

    // ...

    public function update(delta:Float):Void {
        // ...
    }

    // ...

    public function updateAnimations(delta:Float):Void {
        // ...
    }

    // ...

    public function updateBehaviors():Void {
        // ...
    }

    // ...

    public function updateMovementModel(delta:Float):Void {
        // ...
    }

    // ...

    private function _createPart(geometry:Dynamic, skinMap:Texture):MorphBlendMesh {
        // ...
    }

}