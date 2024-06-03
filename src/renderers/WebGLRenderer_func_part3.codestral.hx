import three.renderers.WebGLAnimation;
import three.renderers.WebGLRenderTarget;
import three.renderers.WebGLRenderer_func_part3;
import three.renderers.WebGLState;
import three.renderers.shaders.UniformsLib;
import three.renderers.shaders.UniformsUtils;
import three.scenes.Fog;
import three.scenes.FogExp2;
import three.scenes.Scene;
import three.cameras.Camera;
import three.objects.Group;
import three.objects.LOD;
import three.objects.Light;
import three.objects.Mesh;
import three.objects.Line;
import three.objects.Points;
import three.objects.Sprite;
import three.materials.Material;
import three.materials.MeshBasicMaterial;
import three.materials.ShaderMaterial;
import three.core.Object3D;
import three.core.Raycaster;
import three.core.Vector3;
import three.math.Color;
import three.math.Frustum;
import three.math.Matrix4;
import three.math.Plane;
import three.math.Sphere;
import three.math.Vector4;
import three.textures.Texture;

class WebGLRenderer_func_part3_Haxe {
	var onAnimationFrameCallback:Dynamic = null;
	var animation:WebGLAnimation;
	var _this:WebGLRenderer_func_part3;
	var state:WebGLState;
	var _currentViewport:Vector4;
	var _frustum:Frustum;
	var _projScreenMatrix:Matrix4;
	var _vector3:Vector3;
	var _currentClearColor:Color;
	var _currentClearAlpha:Float;

	public function new() {
		animation = new WebGLAnimation();
		animation.setAnimationLoop(onAnimationFrame);

		if (typeof js.Browser.window.self != 'undefined') animation.setContext(js.Browser.window.self);
	}

	public function onAnimationFrame(time:Int) {
		if (onAnimationFrameCallback != null) onAnimationFrameCallback(time);
	}

	public function onXRSessionStart() {
		animation.stop();
	}

	public function onXRSessionEnd() {
		animation.start();
	}

	public function setAnimationLoop(callback:Dynamic) {
		onAnimationFrameCallback = callback;
		_this.xr.setAnimationLoop(callback);

		if (callback == null) animation.stop(); else animation.start();
	}

	public function render(scene:Scene, camera:Camera) {
		if (camera != null && !camera.isCamera) {
			js.Browser.console.error("THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.");
			return;
		}

		if (_this._isContextLost) return;

		if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();

		if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();

		if (_this.xr.enabled && _this.xr.isPresenting) {
			if (_this.xr.cameraAutoUpdate) _this.xr.updateCamera(camera);
			camera = _this.xr.getCamera();
		}

		// rest of the code...
	}

	public function projectObject(object:Object3D, camera:Camera, groupOrder:Int, sortObjects:Bool) {
		if (!object.visible) return;

		if (object.layers.test(camera.layers)) {
			if (object is Group) {
				groupOrder = object.renderOrder;
			} else if (object is LOD) {
				if (object.autoUpdate) object.update(camera);
			} else if (object is Light) {
				_this.currentRenderState.pushLight(object);
				if (object.castShadow) _this.currentRenderState.pushShadow(object);
			} else if (object is Sprite) {
				// rest of the code...
			} else if (object is Mesh || object is Line || object is Points) {
				// rest of the code...
			}
		}

		// rest of the code...
	}

	public function renderScene(currentRenderList:Dynamic, scene:Scene, camera:Camera, viewport:Vector4 = null) {
		// rest of the code...
	}

	public function renderTransmissionPass(opaqueObjects:Array<Dynamic>, transmissiveObjects:Array<Dynamic>, scene:Scene, camera:Camera) {
		// rest of the code...
	}

	public function renderObjects(renderList:Array<Dynamic>, scene:Scene, camera:Camera) {
		// rest of the code...
	}
}