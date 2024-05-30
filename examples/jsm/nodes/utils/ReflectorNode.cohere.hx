import TextureNode from '../accessors/TextureNode.hx';
import { nodeObject, vec2 } from '../shadernode/ShaderNode.hx';
import { NodeUpdateType } from '../core/constants.hx';
import { viewportTopLeft } from '../display/ViewportNode.hx';
import { Matrix4, Vector2, Vector3, Vector4, Object3D, Plane, RenderTarget, HalfFloatType, LinearMipMapLinearFilter } from 'three';

var _reflectorPlane = Plane.create();
var _normal = Vector3.create();
var _reflectorWorldPosition = Vector3.create();
var _cameraWorldPosition = Vector3.create();
var _rotationMatrix = Matrix4.create();
var _lookAtPosition = Vector3.create(0, 0, -1);
var clipPlane = Vector4.create();

var _view = Vector3.create();
var _target = Vector3.create();
var _q = Vector4.create();

var _size = Vector2.create();

var _defaultRT = RenderTarget.create();
var _defaultUV = vec2(viewportTopLeft.x.oneMinus(), viewportTopLeft.y);

var _inReflector = false;

class ReflectorNode extends TextureNode {
    constructor(parameters = {}) {
        super(_defaultRT.texture, _defaultUV);
        var target = parameters.target ?? Object3D.create();
        var resolution = parameters.resolution ?? 1;
        var generateMipmaps = parameters.generateMipmaps ?? false;
        var bounces = parameters.bounces ?? true;

        this.target = target;
        this.resolution = resolution;
        this.generateMipmaps = generateMipmaps;
        this.bounces = bounces;

        this.updateBeforeType = bounces ? NodeUpdateType.RENDER : NodeUpdateType.FRAME;

        this.virtualCameras = new WeakMap();
        this.renderTargets = new WeakMap();
    }

    _updateResolution(renderTarget, renderer) {
        var resolution = this.resolution;
        renderer.getDrawingBufferSize(_size);
        renderTarget.setSize(Std.int(Math.round(_size.width * resolution)), Std.int(Math.round(_size.height * resolution)));
    }

    setup(builder) {
        this._updateResolution(_defaultRT, builder.renderer);
        return super.setup(builder);
    }

    getTextureNode() {
        return this.textureNode;
    }

    getVirtualCamera(camera) {
        var virtualCamera = this.virtualCameras.get(camera);
        if (virtualCamera == null) {
            virtualCamera = camera.clone();
            this.virtualCameras.set(camera, virtualCamera);
        }
        return virtualCamera;
    }

    getRenderTarget(camera) {
        var renderTarget = this.renderTargets.get(camera);
        if (renderTarget == null) {
            renderTarget = RenderTarget.create(0, 0, { type: HalfFloatType });
            if (this.generateMipmaps) {
                renderTarget.texture.minFilter = LinearMipMapLinearFilter;
                renderTarget.texture.generateMipmaps = true;
            }
            this.renderTargets.set(camera, renderTarget);
        }
        return renderTarget;
    }

    updateBefore(frame) {
        if (this.bounces == false && _inReflector) return false;

        _inReflector = true;

        var scene = frame.scene;
        var camera = frame.camera;
        var renderer = frame.renderer;
        var material = frame.material;
        var target = this.target;

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

        // Avoid rendering when reflector is facing away
        if (_view.dot(_normal) > 0) return;

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

        _q.x = (clipPlane.x.sign() + projectionMatrix.elements[8]) / projectionMatrix.elements[0];
        _q.y = (clipPlane.y.sign() + projectionMatrix.elements[9]) / projectionMatrix.elements[5];
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
    }
}

function reflector(parameters) {
    return nodeObject(new ReflectorNode(parameters));
}

class ReflectorNodeLibrary {
    static reflector($) {
        return reflector($);
    }
}