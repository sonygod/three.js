import hx3d.scene.Mesh;
import hx3d.scene.SceneNode;
import hx3d.material.LambertMaterial;
import hx3d.texture.Texture;
import hx3d.loader.Loader;
import hx3d.loader.MD2Loader;
import hx3d.math.Vector3D;
import hx3d.math.Quaternion;
import hx3d.math.Box3D;
import hx3d.math.MathUtils;

class MD2CharacterComplex {

	public var scale:Float = 1;

	// animation parameters
	public var animationFPS:Int = 6;
	public var transitionFrames:Int = 15;

	// movement model parameters
	public var maxSpeed:Float = 275;
	public var maxReverseSpeed:Float = -275;
	public var frontAcceleration:Float = 600;
	public var backAcceleration:Float = 600;
	public var frontDecceleration:Float = 600;
	public var angularSpeed:Float = 2.5;

	// rig
	public var root:SceneNode;

	public var meshBody:Mesh;
	public var meshWeapon:Mesh;

	public var controls:Dynamic;

	// skins
	public var skinsBody:Array<Texture>;
	public var skinsWeapon:Array<Texture>;

	public var weapons:Array<Mesh>;

	public var currentSkin:Int = -1;

	// internals
	public var onLoadComplete:Dynamic;

	public var meshes:Array<Mesh>;
	public var animations:Dynamic;

	public var loadCounter:Int = 0;

	// internal movement control variables
	public var speed:Float = 0;
	public var bodyOrientation:Float = 0;

	public var walkSpeed:Float = maxSpeed;
	public var crouchSpeed:Float = maxSpeed * 0.5;

	// internal animation parameters
	public var activeAnimation:String = "";
	public var oldAnimation:String = "";

	public function new() {
		root = new SceneNode();
		meshes = [];
	}

	public function enableShadows(enable:Bool) {
		for (i in 0...meshes.length) {
			meshes[i].castShadow = enable;
			meshes[i].receiveShadow = enable;
		}
	}

	public function setVisible(enable:Bool) {
		for (i in 0...meshes.length) {
			meshes[i].visible = enable;
		}
	}

	public function shareParts(original:MD2CharacterComplex) {
		// Implement sharing parts logic here
	}

	public function loadParts(config:Dynamic) {
		// Implement loading parts logic here
	}

	public function setPlaybackRate(rate:Float) {
		// Implement set playback rate logic here
	}

	public function setWireframe(wireframeEnabled:Bool) {
		// Implement set wireframe logic here
	}

	public function setSkin(index:Int) {
		// Implement set skin logic here
	}

	public function setWeapon(index:Int) {
		// Implement set weapon logic here
	}

	public function setAnimation(animationName:String) {
		// Implement set animation logic here
	}

	public function update(delta:Float) {
		// Implement update logic here
	}

	// Implement other methods here

}