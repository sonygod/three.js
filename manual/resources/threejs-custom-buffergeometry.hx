package threejs;

import three.*;

class ThreeJsCustomBufferGeometry {
  static function main() {
    var loader = new TextureLoader();
    var texture = loader.load('manual/examples/resources/images/star-light.png');
    texture.wrapS = RepeatWrapping;
    texture.wrapT = RepeatWrapping;
    texture.repeat.set(3, 1);

    function makeMesh(geometry:Geometry) {
      var material = new MeshPhongMaterial({
        color: 0x663399, // HSL to hex conversion
        side: DoubleSide,
        map: texture
      });
      return new Mesh(geometry, material);
    }

    threejs.LessonUtils.addDiagrams({
      geometryCylinder: {
        create: function() {
          return new Object3D();
        }
      },
      bufferGeometryCylinder: {
        create: function() {
          var numSegments = 24;
          var positions:Array<Float> = [];
          var uvs:Array<Float> = [];
          for (i in 0...numSegments + 1) {
            var u = i / numSegments;
            var a = u * Math.PI * 2;
            var x = Math.sin(a);
            var z = Math.cos(a);
            positions.push(x, -1, z);
            positions.push(x, 1, z);
            uvs.push(u, 0);
            uvs.push(u, 1);
          }

          var indices:Array<Int> = [];
          for (i in 0...numSegments) {
            var ndx = i * 2;
            indices.push(ndx, ndx + 2, ndx + 1);
            indices.push(ndx + 1, ndx + 2, ndx + 3);
          }

          var geometry = new BufferGeometry();
          geometry.setAttribute('position', new BufferAttribute(new Float32Array(positions), 3));
          geometry.setAttribute('uv', new BufferAttribute(new Float32Array(uvs), 2));
          geometry.setIndex(indices);
          geometry.computeVertexNormals();
          geometry.scale(5, 5, 5);
          return makeMesh(geometry);
        }
      }
    });
  }
}