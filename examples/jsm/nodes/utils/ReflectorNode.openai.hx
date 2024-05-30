package three.js.examples.jms.nodes.utils;

import three.js.accessors.TextureNode;
import three.js.shadernode.ShaderNode;
import three.js.core.constants.NodeUpdateType;
import three.js.display.ViewportNode;
import three.js.Matrix4;
import three.js.Vector2;
import three.js.Vector3;
import three.js.Vector4;
import three.js.Object3D;
import three.js.Plane;
import three.js.RenderTarget;
import three.js.HalfFloatType;
import three.js.LinearMipMapLinearFilter;

class ReflectorNode extends TextureNode {
  var target:Object3D;
  var resolution:Float;
  var generateMipmaps:Bool;
  var bounces:Bool;

  var virtualCameras:WeakMap<Object3D, Object3D>;
  var renderTargets:WeakMap<Object3D, RenderTarget>;

  var _reflectorPlane:Plane;
  var _normal:Vector3;
  var _reflectorWorldPosition:Vector3;
  var _cameraWorldPosition:Vector3;
  var _rotationMatrix:Matrix4;
  var _lookAtPosition:Vector3;
  var _view:Vector3;
  var _target:Vector3;
  var _q:Vector4;

  var _size:Vector2;
  var _defaultRT:RenderTarget;
  var _defaultUV:Vector2;

  var _inReflector:Bool;

  public function new(?parameters:{}) {
    super(new TextureNode(_defaultRT.texture, _defaultUV));

    var target:Object3D = parameters.target != null ? parameters.target : new Object3D();
    var resolution:Float = parameters.resolution != null ? parameters.resolution : 1;
    var generateMipmaps:Bool = parameters.generateMipmaps != null ? parameters.generateMipmaps : false;
    var bounces:Bool = parameters.bounces != null ? parameters.bounces : true;

    this.target = target;
    this.resolution = resolution;
    this.generateMipmaps = generateMipmaps;
    this.bounces = bounces;

    this.updateBeforeType = bounces ? NodeUpdateType.RENDER : NodeUpdateType.FRAME;

    this.virtualCameras = new WeakMap<Object3D, Object3D>();
    this.renderTargets = new WeakMap<Object3D, RenderTarget>();
  }

  function _updateResolution(renderTarget:RenderTarget, renderer:Dynamic) {
    var resolution:Float = this.resolution;

    renderer.getDrawingBufferSize(_size);

    renderTarget.setSize(Math.ceil(_size.width * resolution), Math.ceil(_size.height * resolution));
  }

  override function setup(builder:Dynamic) {
    _updateResolution(_defaultRT, builder.renderer);

    return super.setup(builder);
  }

  function getTextureNode():TextureNode {
    return this.textureNode;
  }

  function getVirtualCamera(camera:Object3D) {
    var virtualCamera:Object3D = virtualCameras.get(camera);

    if (virtualCamera == null) {
      virtualCamera = camera.clone();
      virtualCameras.set(camera, virtualCamera);
    }

    return virtualCamera;
  }

  function getRenderTarget(camera:Object3D):RenderTarget {
    var renderTarget:RenderTarget = renderTargets.get(camera);

    if (renderTarget == null) {
      renderTarget = new RenderTarget(0, 0, { type: HalfFloatType });

      if (generateMipmaps) {
        renderTarget.texture.minFilter = LinearMipMapLinearFilter;
        renderTarget.texture.generateMipmaps = true;
      }

      renderTargets.set(camera, renderTarget);
    }

    return renderTarget;
  }

  function updateBefore(frame:Dynamic) {
    if (!bounces && _inReflector) return false;

    _inReflector = true;

    var scene:Dynamic = frame.scene;
    var camera:Object3D = frame.camera;
    var renderer:Dynamic = frame.renderer;
    var material:Dynamic = frame.material;

    var virtualCamera:Object3D = getVirtualCamera(camera);
    var renderTarget:RenderTarget = getRenderTarget(virtualCamera);

    renderer.getDrawingBufferSize(_size);

    _updateResolution(renderTarget, renderer);

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

    // Now update projection matrix with new clip plane, implementing code from: http://www.terathon.com/code/oblique.html
    // Paper explaining this technique: http://www.terathon.com/lengyel/Lengyel-Oblique.pdf
    _reflectorPlane.setFromNormalAndCoplanarPoint(_normal, _reflectorWorldPosition);
    _reflectorPlane.applyMatrix4(virtualCamera.matrixWorldInverse);

    clipPlane.set(_reflectorPlane.normal.x, _reflectorPlane.normal.y, _reflectorPlane.normal.z, _reflectorPlane.constant);

    var projectionMatrix:Matrix4 = virtualCamera.projectionMatrix;

    _q.x = (Math.sign(clipPlane.x) + projectionMatrix.elements[8]) / projectionMatrix.elements[0];
    _q.y = (Math.sign(clipPlane.y) + projectionMatrix.elements[9]) / projectionMatrix.elements[5];
    _q.z = -1.0;
    _q.w = (1.0 + projectionMatrix.elements[10]) / projectionMatrix.elements[14];

    // Calculate the scaled plane vector
    clipPlane.multiplyScalar(1.0 / clipPlane.dot(_q));

    var clipBias:Float = 0;

    // Replacing the third row of the projection matrix
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

function reflector(?parameters:Dynamic):ReflectorNode {
  return nodeObject(new ReflectorNode(parameters));
}