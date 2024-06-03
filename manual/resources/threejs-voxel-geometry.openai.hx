package threejs.voxel.geometry;

import three.js.Three;
import three.js.utils.BufferGeometryUtils;
import threejsLessonUtils.ThreejsLessonUtils;

class VoxelGeometry {
  static function main() {
    var darkMatcher = js.Browser.matcher("(prefers-color-scheme: dark)");
    var isDarkMode = darkMatcher.matches;

    var darkColors = {
      wire: "#DDD"
    };
    var lightColors = {
      wire: "#000"
    };
    var colors = if (isDarkMode) darkColors else lightColors;

    ThreejsLessonUtils.addDiagrams({
      mergedCubes: {
        create: function() {
          var geometries = [];
          var width = 3;
          var height = 2;
          var depth = 2;
          for (y in 0...height) {
            for (z in 0...depth) {
              for (x in 0...width) {
                var geometry = new Three.BoxGeometry(1, 1, 1);
                geometry.applyMatrix4(new Three.Matrix4().makeTranslation(x, y, z));
                geometries.push(geometry);
              }
            }
          }
          var mergedGeometry = BufferGeometryUtils.mergeGeometries(geometries, false);
          var material = new Three.MeshBasicMaterial({
            color: colors.wire,
            wireframe: true
          });
          var mesh = new Three.Mesh(mergedGeometry, material);
          mesh.position.set(0.5 - width / 2, 0.5 - height / 2, 0.5 - depth / 2);
          var base = new Three.Object3D();
          base.add(mesh);
          base.scale.setScalar(3.5);
          return base;
        }
      },
      culledCubes: {
        create: function() {
          var geometry = new Three.BoxGeometry(3, 2, 2, 3, 2, 2);
          var material = new Three.MeshBasicMaterial({
            color: colors.wire,
            wireframe: true
          });
          var mesh = new Three.Mesh(geometry, material);
          mesh.scale.setScalar(3.5);
          return mesh;
        }
      }
    });
  }
}