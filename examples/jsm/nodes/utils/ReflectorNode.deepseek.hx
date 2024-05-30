package three.js.examples.jsm.nodes.utils;

import three.js.examples.jsm.nodes.accessors.TextureNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.core.constants.NodeUpdateType;
import three.js.examples.jsm.display.ViewportNode;
import three.js.three.Matrix4;
import three.js.three.Vector2;
import three.js.three.Vector3;
import three.js.three.Vector4;
import three.js.three.Object3D;
import three.js.three.Plane;
import three.js.three.RenderTarget;
import three.js.three.HalfFloatType;
import three.js.three.LinearMipMapLinearFilter;

class ReflectorNode extends TextureNode {

    static var _reflectorPlane:Plane = new Plane();
    static var _normal:Vector3 = new Vector3();
    static var _reflectorWorldPosition:Vector3 = new Vector3();
    static var _cameraWorldPosition:Vector3 = new Vector3();
    static var _rotationMatrix:Matrix4 = new Matrix4();
    static var _lookAtPosition:Vector3 = new Vector3(0, 0, -1);
    static var clipPlane:Vector4 = new Vector4();

    static var _view:Vector3 = new Vector3();
    static var _target:Vector3 = new Vector3();
    static var _q:Vector4 = new Vector4();

    static var _size:Vector2 = new Vector2();

    static var _defaultRT:RenderTarget = new RenderTarget();
    static var _defaultUV:Vector2 = ShaderNode.vec2(ViewportNode.viewportTopLeft.x.oneMinus(), ViewportNode.viewportTopLeft.y);

    static var _inReflector:Bool = false;

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

    private function _updateResolution(renderTarget:RenderTarget, renderer:Dynamic):Void {
        var resolution:Float = this.resolution;

        renderer.getDrawingBufferSize(_size);

        renderTarget.setSize(Math.round(_size.x * resolution), Math.round(_size.y * resolution));
    }

    public function setup(builder:Dynamic):Dynamic {
        this._updateResolution(_defaultRT, builder.renderer);

        return super.setup(builder);
    }

    public function getTextureNode():Dynamic {
        return this.textureNode;
    }

    public function getVirtualCamera(camera:Dynamic):Dynamic {
        var virtualCamera:Dynamic = this.virtualCameras.get(camera);

        if (virtualCamera == null) {
            virtualCamera = camera.clone();

            this.virtualCameras.set(camera, virtualCamera);
        }

        return virtualCamera;
    }

    public function getRenderTarget(camera:Dynamic):Dynamic {
        var renderTarget:Dynamic = this.renderTargets.get(camera);

        if (renderTarget == null) {
            renderTarget = new RenderTarget(0, 0, {type: HalfFloatType});

            if (this.generateMipmaps == true) {
                renderTarget.texture.minFilter = LinearMipMapLinearFilter;
                renderTarget.texture.generateMipmaps = true;
            }

            this.renderTargets.set(camera, renderTarget);
        }

        return renderTarget;
    }

    public function updateBefore(frame:Dynamic):Dynamic {
        if (this.bounces == false && _inReflector) return false;

        _inReflector = true;

        var scene:Dynamic = frame.scene;
        var camera:Dynamic = frame.camera;
        var renderer:Dynamic = frame.renderer;
        var material:Dynamic = frame.material;

        var virtualCamera:Dynamic = this.getVirtualCamera(camera);
        var renderTarget:Dynamic = this.getRenderTarget(virtualCamera);

        renderer.getDrawingBufferSize(_size);

        this._updateResolution(renderTarget, renderer);

        _reflectorWorldPosition.setFromMatrixPosition(this.target.matrixWorld);
        _cameraWorldPosition.setFromMatrixPosition(camera.matrixWorld);

        _rotationMatrix.extractRotation(this.target.matrixWorld);

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

        var projectionMatrix:Dynamic = virtualCamera.projectionMatrix;

        _q.x = (Math.sign(clipPlane.x) + projectionMatrix.elements[8]) / projectionMatrix.elements[0];
        _q.y = (Math.sign(clipPlane.y) + projectionMatrix.elements[9]) / projectionMatrix.elements[5];
        _q.z = -1.0;
        _q.w = (1.0 + projectionMatrix.elements[10]) / projectionMatrix.elements[14];

        clipPlane.multiplyScalar(1.0 / clipPlane.dot(_q));

        var clipBias:Float = 0;

        projectionMatrix.elements[2] = clipPlane.x;
        projectionMatrix.elements[6] = clipPlane.y;
        projectionMatrix.elements[10] = clipPlane.z - clipBias;
        projectionMatrix.elements[14] = clipPlane.w;

        this.value = renderTarget.texture;

        material.visible = false;

        var currentRenderTarget:Dynamic = renderer.getRenderTarget();

        renderer.setRenderTarget(renderTarget);

        renderer.render(scene, virtualCamera);

        renderer.setRenderTarget(currentRenderTarget);

        material.visible = true;

        _inReflector = false;
    }
}

class Reflector {
    static public function reflector(parameters:Dynamic):Dynamic {
        return ShaderNode.nodeObject(new ReflectorNode(parameters));
    }
}