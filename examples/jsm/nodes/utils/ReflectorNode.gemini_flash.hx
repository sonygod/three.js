import TextureNode from "../accessors/TextureNode";
import {nodeObject, vec2} from "../shadernode/ShaderNode";
import {NodeUpdateType} from "../core/constants";
import {viewportTopLeft} from "../display/ViewportNode";
import {Matrix4, Vector2, Vector3, Vector4, Object3D, Plane, RenderTarget, HalfFloatType, LinearMipMapLinearFilter} from "three";

class ReflectorNode extends TextureNode {
	public target:Object3D;
	public resolution:Float;
	public generateMipmaps:Bool;
	public bounces:Bool;
	public virtualCameras:WeakMap<Dynamic,Dynamic>;
	public renderTargets:WeakMap<Dynamic,Dynamic>;
	public updateBeforeType:NodeUpdateType;

	static _reflectorPlane = new Plane();
	static _normal = new Vector3();
	static _reflectorWorldPosition = new Vector3();
	static _cameraWorldPosition = new Vector3();
	static _rotationMatrix = new Matrix4();
	static _lookAtPosition = new Vector3(0, 0, -1);
	static clipPlane = new Vector4();

	static _view = new Vector3();
	static _target = new Vector3();
	static _q = new Vector4();

	static _size = new Vector2();

	static _defaultRT = new RenderTarget();
	static _defaultUV = vec2(viewportTopLeft.x.oneMinus(), viewportTopLeft.y);

	static _inReflector:Bool = false;

	public function new(parameters:Dynamic = {}) {
		super(_defaultRT.texture, _defaultUV);
		var {target, resolution, generateMipmaps, bounces} = parameters;
		this.target = target != null ? target : new Object3D();
		this.resolution = resolution != null ? resolution : 1;
		this.generateMipmaps = generateMipmaps != null ? generateMipmaps : false;
		this.bounces = bounces != null ? bounces : true;
		this.updateBeforeType = bounces ? NodeUpdateType.RENDER : NodeUpdateType.FRAME;
		this.virtualCameras = new WeakMap();
		this.renderTargets = new WeakMap();
	}

	public function _updateResolution(renderTarget:RenderTarget, renderer:Dynamic) {
		var resolution = this.resolution;
		renderer.getDrawingBufferSize(_size);
		renderTarget.setSize(Math.round(_size.width * resolution), Math.round(_size.height * resolution));
	}

	public function setup(builder:Dynamic) {
		this._updateResolution(_defaultRT, builder.renderer);
		return super.setup(builder);
	}

	public function getTextureNode():Dynamic {
		return this.textureNode;
	}

	public function getVirtualCamera(camera:Dynamic):Dynamic {
		var virtualCamera = this.virtualCameras.get(camera);
		if (virtualCamera == null) {
			virtualCamera = camera.clone();
			this.virtualCameras.set(camera, virtualCamera);
		}
		return virtualCamera;
	}

	public function getRenderTarget(camera:Dynamic):Dynamic {
		var renderTarget = this.renderTargets.get(camera);
		if (renderTarget == null) {
			renderTarget = new RenderTarget(0, 0, {type: HalfFloatType});
			if (this.generateMipmaps) {
				renderTarget.texture.minFilter = LinearMipMapLinearFilter;
				renderTarget.texture.generateMipmaps = true;
			}
			this.renderTargets.set(camera, renderTarget);
		}
		return renderTarget;
	}

	public function updateBefore(frame:Dynamic):Bool {
		if (this.bounces == false && _inReflector) return false;
		_inReflector = true;
		var {scene, camera, renderer, material} = frame;
		var {target} = this;
		var virtualCamera = this.getVirtualCamera(camera);
		var renderTarget = this.getRenderTarget(virtualCamera);
		renderer.getDrawingBufferSize(_size);
		this._updateResolution(renderTarget, renderer);
		_reflectorWorldPosition.setFromMatrixPosition(target.matrixWorld);
		_cameraWorldPosition.setFromMatrixPosition(camera.matrixWorld);
		_rotationMatrix.extractRotation(target.matrixWorld);
		_normal.set(0, 0, 1);
		_normal.applyMatrix4(_rotationMatrix);
		_view.subVectors(_reflectorWorldPosition, _cameraWorldPosition);
		if (_view.dot(_normal) > 0) return false;
		_view.reflect(_normal).negate();
		_view.add(_reflectorWorldPosition);
		_rotationMatrix.extractRotation(camera.matrixWorld);
		_lookAtPosition.set(0, 0, -1);
		_lookAtPosition.applyMatrix4(_rotationMatrix);
		_lookAtPosition.add(_cameraWorldPosition);
		_target.subVectors(_reflectorWorldPosition, _lookAtPosition);
		_target.reflect(_normal).negate();
		_target.add(_reflectorWorldPosition);
		virtualCamera.coordinateSystem = camera.coordinateSystem;
		virtualCamera.position.copy(_view);
		virtualCamera.up.set(0, 1, 0);
		virtualCamera.up.applyMatrix4(_rotationMatrix);
		virtualCamera.up.reflect(_normal);
		virtualCamera.lookAt(_target);
		virtualCamera.near = camera.near;
		virtualCamera.far = camera.far;
		virtualCamera.updateMatrixWorld();
		virtualCamera.projectionMatrix.copy(camera.projectionMatrix);
		_reflectorPlane.setFromNormalAndCoplanarPoint(_normal, _reflectorWorldPosition);
		_reflectorPlane.applyMatrix4(virtualCamera.matrixWorldInverse);
		clipPlane.set(_reflectorPlane.normal.x, _reflectorPlane.normal.y, _reflectorPlane.normal.z, _reflectorPlane.constant);
		var projectionMatrix = virtualCamera.projectionMatrix;
		_q.x = (Math.sign(clipPlane.x) + projectionMatrix.elements[8]) / projectionMatrix.elements[0];
		_q.y = (Math.sign(clipPlane.y) + projectionMatrix.elements[9]) / projectionMatrix.elements[5];
		_q.z = -1.0;
		_q.w = (1.0 + projectionMatrix.elements[10]) / projectionMatrix.elements[14];
		clipPlane.multiplyScalar(1.0 / clipPlane.dot(_q));
		var clipBias = 0;
		projectionMatrix.elements[2] = clipPlane.x;
		projectionMatrix.elements[6] = clipPlane.y;
		projectionMatrix.elements[10] = clipPlane.z - clipBias;
		projectionMatrix.elements[14] = clipPlane.w;
		this.value = renderTarget.texture;
		material.visible = false;
		var currentRenderTarget = renderer.getRenderTarget();
		renderer.setRenderTarget(renderTarget);
		renderer.render(scene, virtualCamera);
		renderer.setRenderTarget(currentRenderTarget);
		material.visible = true;
		_inReflector = false;
		return true;
	}
}

export function reflector(parameters:Dynamic):Dynamic {
	return nodeObject(new ReflectorNode(parameters));
}

export default ReflectorNode;