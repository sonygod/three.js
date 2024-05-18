package three.js.examples.jsm.nodes.utils;

import three.js.accessors.TextureNode;
import three.js.shadernode.ShaderNode;
import three.js.core.constants.NodeUpdateType;
import three.js.display.ViewportNode;

import three.Math.Matrix4;
import three.Math.Vector2;
import three.Math.Vector3;
import three.Math.Vector4;
import three.Object3D;
import three.Plane;
import three.RenderTarget;
import three.HalfFloatType;
import three.LinearMipMapLinearFilter;

class ReflectorNode extends TextureNode {
    private var _reflectorPlane:Plane;
    private var _normal:Vector3;
    private var _reflectorWorldPosition:Vector3;
    private var _cameraWorldPosition:Vector3;
    private var _rotationMatrix:Matrix4;
    private var _lookAtPosition:Vector3;
    private var clipPlane:Vector4;

    private var _view:Vector3;
    private var _target:Vector3;
    private var _q:Vector4;

    private var _size:Vector2;

    private var _defaultRT:RenderTarget;
    private var _defaultUV:Vector2;
    private var _inReflector:Bool;

    public function new(parameters:Dynamic = {}) {
        super(_defaultRT.texture, _defaultUV);

        var target:Object3D = parameters.target != null ? parameters.target : new Object3D();
        var resolution:Float = parameters.resolution != null ? parameters.resolution : 1;
        var generateMipmaps:Bool = parameters.generateMipmaps != null ? parameters.generateMipmaps : false;
        var bounces:Bool = parameters.bounces != null ? parameters.bounces : true;

        this.target = target;
        this.resolution = resolution;
        this.generateMipmaps = generateMipmaps;
        this.bounces = bounces;

        this.updateBeforeType = bounces ? NodeUpdateType.RENDER : NodeUpdateType.FRAME;

        this.virtualCameras = new WeakMap();
        this.renderTargets = new WeakMap();
    }

    private function _updateResolution(renderTarget:RenderTarget, renderer:Dynamic) {
        var resolution:Float = this.resolution;

        renderer.getDrawingBufferSize(_size);

        renderTarget.setSize(Math.round(_size.width * resolution), Math.round(_size.height * resolution));
    }

    public function setup(builder:Dynamic):Void {
        this._updateResolution(_defaultRT, builder.renderer);

        return super.setup(builder);
    }

    public function getTextureNode():TextureNode {
        return this.textureNode;
    }

    public function getVirtualCamera(camera:Object3D):Object3D {
        var virtualCamera:Object3D = this.virtualCameras.get(camera);

        if (virtualCamera == null) {
            virtualCamera = camera.clone();

            this.virtualCameras.set(camera, virtualCamera);
        }

        return virtualCamera;
    }

    public function getRenderTarget(camera:Object3D):RenderTarget {
        var renderTarget:RenderTarget = this.renderTargets.get(camera);

        if (renderTarget == null) {
            renderTarget = new RenderTarget(0, 0, { type: HalfFloatType });

            if (this.generateMipmaps) {
                renderTarget.texture.minFilter = LinearMipMapLinearFilter;
                renderTarget.texture.generateMipmaps = true;
            }

            this.renderTargets.set(camera, renderTarget);
        }

        return renderTarget;
    }

    public function updateBefore(frame:Dynamic):Void {
        if (!this.bounces && _inReflector) return;

        _inReflector = true;

        var scene:Dynamic = frame.scene;
        var camera:Object3D = frame.camera;
        var renderer:Dynamic = frame.renderer;
        var material:Dynamic = frame.material;

        var virtualCamera:Object3D = this.getVirtualCamera(camera);
        var renderTarget:RenderTarget = this.getRenderTarget(virtualCamera);

        renderer.getDrawingBufferSize(_size);

        this._updateResolution(renderTarget, renderer);

        _reflectorWorldPosition.setFromMatrixPosition(target.matrixWorld);
        _cameraWorldPosition.setFromMatrixPosition(camera.matrixWorld);

        _rotationMatrix.extractRotation(target.matrixWorld);

        _normal.set(0, 0, 1);
        _normal.applyMatrix4(_rotationMatrix);

        _view.subVectors(_reflectorWorldPosition, _cameraWorldPosition);

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

        var projectionMatrix:Matrix4 = virtualCamera.projectionMatrix;

        _q.x = (Math.sign(clipPlane.x) + projectionMatrix.elements[8]) / projectionMatrix.elements[0];
        _q.y = (Math.sign(clipPlane.y) + projectionMatrix.elements[9]) / projectionMatrix.elements[5];
        _q.z = -1.0;
        _q.w = (1.0 + projectionMatrix.elements[10]) / projectionMatrix.elements[14];

        clipPlane.multiplyScalar(1.0 / clipPlane.dot(_q));

        var clipBias:Float = 0.0;

        projectionMatrix.elements[2] = clipPlane.x;
        projectionMatrix.elements[6] = clipPlane.y;
        projectionMatrix.elements[10] = clipPlane.z - clipBias;
        projectionMatrix.elements[14] = clipPlane.w;

        this.value = renderTarget.texture;

        material.visible = false;

        var currentRenderTarget:RenderTarget = renderer.getRenderTarget();

        renderer.setRenderTarget(renderTarget);

        renderer.render(scene, virtualCamera);

        renderer.setRenderTarget(currentRenderTarget);

        material.visible = true;

        _inReflector = false;
    }
}

// exports
var reflector:Dynamic = function(parameters:Dynamic) {
    return nodeObject(new ReflectorNode(parameters));
}

export default ReflectorNode;