package three.js.examples.jsm.controls;

import three.math.EllipseCurve;
import three.math.BufferGeometry;
import three.math.LineBasicMaterial;
import three.math.Line;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector3;
import three.core.Object3D;

class ArcballControls {
  // ...

  public function setTbRadius(value:Float):Void {
    radiusFactor = value;
    _tbRadius = calculateTbRadius(camera);

    var curve:EllipseCurve = new EllipseCurve(0, 0, _tbRadius, _tbRadius);
    var points:Array<Vector3> = curve.getPoints(_curvePts);
    var curveGeometry:BufferGeometry = new BufferGeometry().setFromPoints(points);

    for (gizmo in _gizmos.children) {
      gizmo.geometry = curveGeometry;
    }

    dispatchEvent(_changeEvent);
  }

  public function makeGizmos(tbCenter:Vector3, tbRadius:Float):Void {
    var curve:EllipseCurve = new EllipseCurve(0, 0, tbRadius, tbRadius);
    var points:Array<Vector3> = curve.getPoints(_curvePts);
    var curveGeometry:BufferGeometry = new BufferGeometry().setFromPoints(points);

    var curveMaterialX:LineBasicMaterial = new LineBasicMaterial({color: 0xff8080, fog: false, transparent: true, opacity: 0.6});
    var curveMaterialY:LineBasicMaterial = new LineBasicMaterial({color: 0x80ff80, fog: false, transparent: true, opacity: 0.6});
    var curveMaterialZ:LineBasicMaterial = new LineBasicMaterial({color: 0x8080ff, fog: false, transparent: true, opacity: 0.6});

    var gizmoX:Line = new Line(curveGeometry, curveMaterialX);
    var gizmoY:Line = new Line(curveGeometry, curveMaterialY);
    var gizmoZ:Line = new Line(curveGeometry, curveMaterialZ);

    var rotation:Float = Math.PI * 0.5;
    gizmoX.rotation.x = rotation;
    gizmoY.rotation.y = rotation;

    // ...

    _gizmoMatrixState.identity().setPosition(tbCenter);
    _gizmoMatrixState.copy(_gizmoMatrixState0);

    // ...
  }

  public function onFocusAnim(time:Float, point:Vector3, cameraMatrix:Matrix4, gizmoMatrix:Matrix4):Void {
    // ...
  }

  public function onRotationAnim(time:Float, rotationAxis:Vector3, w0:Float):Void {
    // ...
  }

  public function pan(p0:Vector3, p1:Vector3, adjust:Bool = false):Void {
    // ...
  }

  public function reset():Void {
    // ...
  }

  public function rotate(axis:Vector3, angle:Float):Void {
    // ...
  }

  public function copyState():Void {
    // ...
  }

  public function pasteState():Void {
    // ...
  }

  public function saveState():Void {
    // ...
  }

  public function scale(size:Float, point:Vector3, scaleGizmos:Bool = true):Void {
    // ...
  }

  public function setFov(value:Float):Void {
    // ...
  }

  public function setTransformationMatrices(camera:Matrix4 = null, gizmos:Matrix4 = null):Void {
    // ...
  }
}