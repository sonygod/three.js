import three.math.Quaternion;
import three.math.Vector3;
import three.core.Object3D;
import three.core.AnimationMixer;
import three.core.AnimationClip;
import three.loaders.gltf.CCDIKSolver;
import three.loaders.gltf.MMDPhysics;

class MMDAnimationHelper {

	private var _meshes:Array<Dynamic>;
	private var _camera:Object3D;
	private var _cameraTarget:Object3D;
	private var _audio:Dynamic;
	private var _audioManager:AudioManager;
	private var _objects:Map<Dynamic, Dynamic>;
	private var _configuration:Dynamic;
	private var _enabled:Dynamic;
	private var _onBeforePhysics:Dynamic;
	private var _sharedPhysics:Bool;
	private var _masterPhysics:Dynamic;

	public function new(params:Dynamic = null) {
		this._meshes = [];
		this._camera = null;
		this._cameraTarget = new Object3D();
		this._cameraTarget.name = 'target';
		this._audio = null;
		this._audioManager = null;
		this._objects = new Map<Dynamic, Dynamic>();
		this._configuration = {
			sync: (params != null && params.sync != undefined) ? params.sync : true,
			afterglow: (params != null && params.afterglow != undefined) ? params.afterglow : 0.0,
			resetPhysicsOnLoop: (params != null && params.resetPhysicsOnLoop != undefined) ? params.resetPhysicsOnLoop : true,
			pmxAnimation: (params != null && params.pmxAnimation != undefined) ? params.pmxAnimation : false
		};
		this._enabled = {
			animation: true,
			ik: true,
			grant: true,
			physics: true,
			cameraAnimation: true
		};
		this._onBeforePhysics = function ( /* mesh */ ) {};
		this._sharedPhysics = false;
		this._masterPhysics = null;
	}

	//... (other methods follow)

}

class AudioManager {

	public var audio:Dynamic;
	public var elapsedTime:Float;
	public var currentTime:Float;
	public var delayTime:Float;
	public var audioDuration:Float;
	public var duration:Float;

	public function new(audio:Dynamic, params:Dynamic = null) {
		this.audio = audio;
		this.elapsedTime = 0.0;
		this.currentTime = 0.0;
		this.delayTime = (params != null && params.delayTime != undefined) ? params.delayTime : 0.0;
		this.audioDuration = this.audio.buffer.duration;
		this.duration = this.audioDuration + this.delayTime;
	}

	//... (other methods follow)

}

//... (GrantSolver class follows)