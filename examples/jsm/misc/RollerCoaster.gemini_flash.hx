import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;
import three.math.Quaternion;
import three.math.Color;
import three.core.Raycaster;
import three.objects.Mesh;

class RollerCoasterGeometry extends BufferGeometry {

  public function new(curve:Dynamic, divisions:Int) {
    super();

    var vertices:Array<Float> = [];
    var normals:Array<Float> = [];
    var colors:Array<Float> = [];

    var color1:Array<Float> = [1, 1, 1];
    var color2:Array<Float> = [1, 1, 0];

    var up = new Vector3(0, 1, 0);
    var forward = new Vector3();
    var right = new Vector3();

    var quaternion = new Quaternion();
    var prevQuaternion = new Quaternion();
    prevQuaternion.setFromAxisAngle(up, Math.PI / 2);

    var point = new Vector3();
    var prevPoint = new Vector3();
    prevPoint.copy(curve.getPointAt(0));

    // shapes

    var step:Array<Vector3> = [
      new Vector3(-0.225, 0, 0),
      new Vector3(0, -0.050, 0),
      new Vector3(0, -0.175, 0),

      new Vector3(0, -0.050, 0),
      new Vector3(0.225, 0, 0),
      new Vector3(0, -0.175, 0)
    ];

    var PI2 = Math.PI * 2;

    var sides = 5;
    var tube1:Array<Vector3> = [];

    for (i in 0...sides) {

      var angle = (i / sides) * PI2;
      tube1.push(new Vector3(Math.sin(angle) * 0.06, Math.cos(angle) * 0.06, 0));

    }

    sides = 6;
    var tube2:Array<Vector3> = [];

    for (i in 0...sides) {

      var angle = (i / sides) * PI2;
      tube2.push(new Vector3(Math.sin(angle) * 0.025, Math.cos(angle) * 0.025, 0));

    }

    var vector = new Vector3();
    var normal = new Vector3();

    function drawShape(shape:Array<Vector3>, color:Array<Float>) {

      normal.set(0, 0, -1).applyQuaternion(quaternion);

      for (j in 0...shape.length) {

        vector.copy(shape[j]);
        vector.applyQuaternion(quaternion);
        vector.add(point);

        vertices.push(vector.x, vector.y, vector.z);
        normals.push(normal.x, normal.y, normal.z);
        colors.push(color[0], color[1], color[2]);

      }

      normal.set(0, 0, 1).applyQuaternion(quaternion);

      for (j in shape.length - 1...0) {

        vector.copy(shape[j]);
        vector.applyQuaternion(quaternion);
        vector.add(point);

        vertices.push(vector.x, vector.y, vector.z);
        normals.push(normal.x, normal.y, normal.z);
        colors.push(color[0], color[1], color[2]);

      }

    }

    var vector1 = new Vector3();
    var vector2 = new Vector3();
    var vector3 = new Vector3();
    var vector4 = new Vector3();

    var normal1 = new Vector3();
    var normal2 = new Vector3();
    var normal3 = new Vector3();
    var normal4 = new Vector3();

    function extrudeShape(shape:Array<Vector3>, offset:Vector3, color:Array<Float>) {

      for (j in 0...shape.length) {

        var point1 = shape[j];
        var point2 = shape[(j + 1) % shape.length];

        vector1.copy(point1).add(offset);
        vector1.applyQuaternion(quaternion);
        vector1.add(point);

        vector2.copy(point2).add(offset);
        vector2.applyQuaternion(quaternion);
        vector2.add(point);

        vector3.copy(point2).add(offset);
        vector3.applyQuaternion(prevQuaternion);
        vector3.add(prevPoint);

        vector4.copy(point1).add(offset);
        vector4.applyQuaternion(prevQuaternion);
        vector4.add(prevPoint);

        vertices.push(vector1.x, vector1.y, vector1.z);
        vertices.push(vector2.x, vector2.y, vector2.z);
        vertices.push(vector4.x, vector4.y, vector4.z);

        vertices.push(vector2.x, vector2.y, vector2.z);
        vertices.push(vector3.x, vector3.y, vector3.z);
        vertices.push(vector4.x, vector4.y, vector4.z);

        //

        normal1.copy(point1);
        normal1.applyQuaternion(quaternion);
        normal1.normalize();

        normal2.copy(point2);
        normal2.applyQuaternion(quaternion);
        normal2.normalize();

        normal3.copy(point2);
        normal3.applyQuaternion(prevQuaternion);
        normal3.normalize();

        normal4.copy(point1);
        normal4.applyQuaternion(prevQuaternion);
        normal4.normalize();

        normals.push(normal1.x, normal1.y, normal1.z);
        normals.push(normal2.x, normal2.y, normal2.z);
        normals.push(normal4.x, normal4.y, normal4.z);

        normals.push(normal2.x, normal2.y, normal2.z);
        normals.push(normal3.x, normal3.y, normal3.z);
        normals.push(normal4.x, normal4.y, normal4.z);

        colors.push(color[0], color[1], color[2]);
        colors.push(color[0], color[1], color[2]);
        colors.push(color[0], color[1], color[2]);

        colors.push(color[0], color[1], color[2]);
        colors.push(color[0], color[1], color[2]);
        colors.push(color[0], color[1], color[2]);

      }

    }

    var offset = new Vector3();

    for (i in 1...divisions + 1) {

      point.copy(curve.getPointAt(i / divisions));

      up.set(0, 1, 0);

      forward.subVectors(point, prevPoint).normalize();
      right.crossVectors(up, forward).normalize();
      up.crossVectors(forward, right);

      var angle = Math.atan2(forward.x, forward.z);

      quaternion.setFromAxisAngle(up, angle);

      if (i % 2 == 0) {

        drawShape(step, color2);

      }

      extrudeShape(tube1, offset.set(0, -0.125, 0), color2);
      extrudeShape(tube2, offset.set(0.2, 0, 0), color1);
      extrudeShape(tube2, offset.set(-0.2, 0, 0), color1);

      prevPoint.copy(point);
      prevQuaternion.copy(quaternion);

    }

    // console.log(vertices.length);

    this.setAttribute('position', new BufferAttribute(new Float32Array(vertices), 3));
    this.setAttribute('normal', new BufferAttribute(new Float32Array(normals), 3));
    this.setAttribute('color', new BufferAttribute(new Float32Array(colors), 3));

  }

}

class RollerCoasterLiftersGeometry extends BufferGeometry {

  public function new(curve:Dynamic, divisions:Int) {

    super();

    var vertices:Array<Float> = [];
    var normals:Array<Float> = [];

    var quaternion = new Quaternion();

    var up = new Vector3(0, 1, 0);

    var point = new Vector3();
    var tangent = new Vector3();

    // shapes

    var tube1:Array<Vector3> = [
      new Vector3(0, 0.05, -0.05),
      new Vector3(0, 0.05, 0.05),
      new Vector3(0, -0.05, 0)
    ];

    var tube2:Array<Vector3> = [
      new Vector3(-0.05, 0, 0.05),
      new Vector3(-0.05, 0, -0.05),
      new Vector3(0.05, 0, 0)
    ];

    var tube3:Array<Vector3> = [
      new Vector3(0.05, 0, -0.05),
      new Vector3(0.05, 0, 0.05),
      new Vector3(-0.05, 0, 0)
    ];

    var vector1 = new Vector3();
    var vector2 = new Vector3();
    var vector3 = new Vector3();
    var vector4 = new Vector3();

    var normal1 = new Vector3();
    var normal2 = new Vector3();
    var normal3 = new Vector3();
    var normal4 = new Vector3();

    function extrudeShape(shape:Array<Vector3>, fromPoint:Vector3, toPoint:Vector3) {

      for (j in 0...shape.length) {

        var point1 = shape[j];
        var point2 = shape[(j + 1) % shape.length];

        vector1.copy(point1);
        vector1.applyQuaternion(quaternion);
        vector1.add(fromPoint);

        vector2.copy(point2);
        vector2.applyQuaternion(quaternion);
        vector2.add(fromPoint);

        vector3.copy(point2);
        vector3.applyQuaternion(quaternion);
        vector3.add(toPoint);

        vector4.copy(point1);
        vector4.applyQuaternion(quaternion);
        vector4.add(toPoint);

        vertices.push(vector1.x, vector1.y, vector1.z);
        vertices.push(vector2.x, vector2.y, vector2.z);
        vertices.push(vector4.x, vector4.y, vector4.z);

        vertices.push(vector2.x, vector2.y, vector2.z);
        vertices.push(vector3.x, vector3.y, vector3.z);
        vertices.push(vector4.x, vector4.y, vector4.z);

        //

        normal1.copy(point1);
        normal1.applyQuaternion(quaternion);
        normal1.normalize();

        normal2.copy(point2);
        normal2.applyQuaternion(quaternion);
        normal2.normalize();

        normal3.copy(point2);
        normal3.applyQuaternion(quaternion);
        normal3.normalize();

        normal4.copy(point1);
        normal4.applyQuaternion(quaternion);
        normal4.normalize();

        normals.push(normal1.x, normal1.y, normal1.z);
        normals.push(normal2.x, normal2.y, normal2.z);
        normals.push(normal4.x, normal4.y, normal4.z);

        normals.push(normal2.x, normal2.y, normal2.z);
        normals.push(normal3.x, normal3.y, normal3.z);
        normals.push(normal4.x, normal4.y, normal4.z);

      }

    }

    var fromPoint = new Vector3();
    var toPoint = new Vector3();

    for (i in 1...divisions + 1) {

      point.copy(curve.getPointAt(i / divisions));
      tangent.copy(curve.getTangentAt(i / divisions));

      var angle = Math.atan2(tangent.x, tangent.z);

      quaternion.setFromAxisAngle(up, angle);

      //

      if (point.y > 10) {

        fromPoint.set(-0.75, -0.35, 0);
        fromPoint.applyQuaternion(quaternion);
        fromPoint.add(point);

        toPoint.set(0.75, -0.35, 0);
        toPoint.applyQuaternion(quaternion);
        toPoint.add(point);

        extrudeShape(tube1, fromPoint, toPoint);

        fromPoint.set(-0.7, -0.3, 0);
        fromPoint.applyQuaternion(quaternion);
        fromPoint.add(point);

        toPoint.set(-0.7, -point.y, 0);
        toPoint.applyQuaternion(quaternion);
        toPoint.add(point);

        extrudeShape(tube2, fromPoint, toPoint);

        fromPoint.set(0.7, -0.3, 0);
        fromPoint.applyQuaternion(quaternion);
        fromPoint.add(point);

        toPoint.set(0.7, -point.y, 0);
        toPoint.applyQuaternion(quaternion);
        toPoint.add(point);

        extrudeShape(tube3, fromPoint, toPoint);

      } else {

        fromPoint.set(0, -0.2, 0);
        fromPoint.applyQuaternion(quaternion);
        fromPoint.add(point);

        toPoint.set(0, -point.y, 0);
        toPoint.applyQuaternion(quaternion);
        toPoint.add(point);

        extrudeShape(tube3, fromPoint, toPoint);

      }

    }

    this.setAttribute('position', new BufferAttribute(new Float32Array(vertices), 3));
    this.setAttribute('normal', new BufferAttribute(new Float32Array(normals), 3));

  }

}

class RollerCoasterShadowGeometry extends BufferGeometry {

  public function new(curve:Dynamic, divisions:Int) {

    super();

    var vertices:Array<Float> = [];

    var up = new Vector3(0, 1, 0);
    var forward = new Vector3();

    var quaternion = new Quaternion();
    var prevQuaternion = new Quaternion();
    prevQuaternion.setFromAxisAngle(up, Math.PI / 2);

    var point = new Vector3();

    var prevPoint = new Vector3();
    prevPoint.copy(curve.getPointAt(0));
    prevPoint.y = 0;

    var vector1 = new Vector3();
    var vector2 = new Vector3();
    var vector3 = new Vector3();
    var vector4 = new Vector3();

    for (i in 1...divisions + 1) {

      point.copy(curve.getPointAt(i / divisions));
      point.y = 0;

      forward.subVectors(point, prevPoint);

      var angle = Math.atan2(forward.x, forward.z);

      quaternion.setFromAxisAngle(up, angle);

      vector1.set(-0.3, 0, 0);
      vector1.applyQuaternion(quaternion);
      vector1.add(point);

      vector2.set(0.3, 0, 0);
      vector2.applyQuaternion(quaternion);
      vector2.add(point);

      vector3.set(0.3, 0, 0);
      vector3.applyQuaternion(prevQuaternion);
      vector3.add(prevPoint);

      vector4.set(-0.3, 0, 0);
      vector4.applyQuaternion(prevQuaternion);
      vector4.add(prevPoint);

      vertices.push(vector1.x, vector1.y, vector1.z);
      vertices.push(vector2.x, vector2.y, vector2.z);
      vertices.push(vector4.x, vector4.y, vector4.z);

      vertices.push(vector2.x, vector2.y, vector2.z);
      vertices.push(vector3.x, vector3.y, vector3.z);
      vertices.push(vector4.x, vector4.y, vector4.z);

      prevPoint.copy(point);
      prevQuaternion.copy(quaternion);

    }

    this.setAttribute('position', new BufferAttribute(new Float32Array(vertices), 3));

  }

}

class SkyGeometry extends BufferGeometry {

  public function new() {

    super();

    var vertices:Array<Float> = [];

    for (i in 0...100) {

      var x = Math.random() * 800 - 400;
      var y = Math.random() * 50 + 50;
      var z = Math.random() * 800 - 400;

      var size = Math.random() * 40 + 20;

      vertices.push(x - size, y, z - size);
      vertices.push(x + size, y, z - size);
      vertices.push(x - size, y, z + size);

      vertices.push(x + size, y, z - size);
      vertices.push(x + size, y, z + size);
      vertices.push(x - size, y, z + size);

    }


    this.setAttribute('position', new BufferAttribute(new Float32Array(vertices), 3));

  }

}

class TreesGeometry extends BufferGeometry {

  public function new(landscape:Mesh) {

    super();

    var vertices:Array<Float> = [];
    var colors:Array<Float> = [];

    var raycaster = new Raycaster();
    raycaster.ray.direction.set(0, -1, 0);

    var _color = new Color();

    for (i in 0...2000) {

      var x = Math.random() * 500 - 250;
      var z = Math.random() * 500 - 250;

      raycaster.ray.origin.set(x, 50, z);

      var intersections = raycaster.intersectObject(landscape);

      if (intersections.length == 0) continue;

      var y = intersections[0].point.y;

      var height = Math.random() * 5 + 0.5;

      var angle = Math.random() * Math.PI * 2;

      vertices.push(x + Math.sin(angle), y, z + Math.cos(angle));
      vertices.push(x, y + height, z);
      vertices.push(x + Math.sin(angle + Math.PI), y, z + Math.cos(angle + Math.PI));

      angle += Math.PI / 2;

      vertices.push(x + Math.sin(angle), y, z + Math.cos(angle));
      vertices.push(x, y + height, z);
      vertices.push(x + Math.sin(angle + Math.PI), y, z + Math.cos(angle + Math.PI));

      var random = Math.random() * 0.1;

      for (j in 0...6) {

        _color.setRGB(0.2 + random, 0.4 + random, 0);

        colors.push(_color.r, _color.g, _color.b);

      }

    }

    this.setAttribute('position', new BufferAttribute(new Float32Array(vertices), 3));
    this.setAttribute('color', new BufferAttribute(new Float32Array(colors), 3));

  }

}

class RollerCoaster {

  public static function main() {

    // ...

  }

}