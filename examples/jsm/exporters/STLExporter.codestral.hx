import three.Vector3;

class STLExporter {

  public function new() {}

  public function parse(scene:Mesh, options:Map<String, Dynamic> = null):Dynamic {
    if(options == null) options = new Map<String, Dynamic>();
    if(!options.exists("binary")) options.set("binary", false);

    var binary:Bool = options.get("binary");

    var objects:Array<Dynamic> = [];
    var triangles:Int = 0;

    scene.traverse(function(object:Mesh) {
      if(js.Boot.getClass(object) == js.Boot.getClass('three.Mesh')) {
        var geometry = object.geometry;

        var index = geometry.index;
        var positionAttribute = geometry.getAttribute('position');

        triangles += (index != null) ? (index.count / 3) : (positionAttribute.count / 3);

        objects.push({
          object3d: object,
          geometry: geometry
        });
      }
    });

    var output:Dynamic;
    var offset:Int = 80; // skip header

    if(binary) {
      var bufferLength = triangles * 2 + triangles * 3 * 4 * 4 + 80 + 4;
      var arrayBuffer = js.html.ArrayBuffer.alloc(bufferLength);
      output = js.html.DataView.alloc(arrayBuffer);
      output.setUint32(offset, triangles, true); offset += 4;
    } else {
      output = 'solid exported\n';
    }

    var vA = new Vector3();
    var vB = new Vector3();
    var vC = new Vector3();
    var cb = new Vector3();
    var ab = new Vector3();
    var normal = new Vector3();

    for(var i = 0; i < objects.length; i++) {
      var object = objects[i].object3d;
      var geometry = objects[i].geometry;

      var index = geometry.index;
      var positionAttribute = geometry.getAttribute('position');

      if(index != null) {
        for(var j = 0; j < index.count; j += 3) {
          var a = index.getX(j + 0);
          var b = index.getX(j + 1);
          var c = index.getX(j + 2);

          writeFace(a, b, c, positionAttribute, object);
        }
      } else {
        for(var j = 0; j < positionAttribute.count; j += 3) {
          var a = j + 0;
          var b = j + 1;
          var c = j + 2;

          writeFace(a, b, c, positionAttribute, object);
        }
      }
    }

    if(!binary) {
      output += 'endsolid exported\n';
    }

    return output;

    function writeFace(a:Int, b:Int, c:Int, positionAttribute:Dynamic, object:Mesh) {
      vA.fromBufferAttribute(positionAttribute, a);
      vB.fromBufferAttribute(positionAttribute, b);
      vC.fromBufferAttribute(positionAttribute, c);

      if(js.Boot.getClass(object) == js.Boot.getClass('three.SkinnedMesh')) {
        object.applyBoneTransform(a, vA);
        object.applyBoneTransform(b, vB);
        object.applyBoneTransform(c, vC);
      }

      vA.applyMatrix4(object.matrixWorld);
      vB.applyMatrix4(object.matrixWorld);
      vC.applyMatrix4(object.matrixWorld);

      writeNormal(vA, vB, vC);

      writeVertex(vA);
      writeVertex(vB);
      writeVertex(vC);

      if(binary) {
        output.setUint16(offset, 0, true); offset += 2;
      } else {
        output += '\t\tendloop\n';
        output += '\tendfacet\n';
      }
    }

    function writeNormal(vA:Vector3, vB:Vector3, vC:Vector3) {
      cb.subVectors(vC, vB);
      ab.subVectors(vA, vB);
      cb.cross(ab).normalize();

      normal.copy(cb).normalize();

      if(binary) {
        output.setFloat32(offset, normal.x, true); offset += 4;
        output.setFloat32(offset, normal.y, true); offset += 4;
        output.setFloat32(offset, normal.z, true); offset += 4;
      } else {
        output += '\tfacet normal ' + normal.x + ' ' + normal.y + ' ' + normal.z + '\n';
        output += '\t\touter loop\n';
      }
    }

    function writeVertex(vertex:Vector3) {
      if(binary) {
        output.setFloat32(offset, vertex.x, true); offset += 4;
        output.setFloat32(offset, vertex.y, true); offset += 4;
        output.setFloat32(offset, vertex.z, true); offset += 4;
      } else {
        output += '\t\t\tvertex ' + vertex.x + ' ' + vertex.y + ' ' + vertex.z + '\n';
      }
    }
  }
}