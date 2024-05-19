package three.js.manual.resources;

import three.js.Three;

class threejsCameras {
  static function addShape(color:String, geometry:Geometry):Mesh {
    var material = new MeshPhongMaterial({ color: color });
    return new Mesh(geometry, material);
  }

  static function main() {
    threejsLessonUtils.addDiagrams({
      shapeCube: {
        create: function() {
          var width = 8;
          var height = 8;
          var depth = 8;
          return addShape('hsl(150,100%,40%)', new BoxGeometry(width, height, depth));
        }
      },
      shapeCone: {
        create: function() {
          var radius = 6;
          var height = 8;
          var segments = 24;
          return addShape('hsl(160,100%,40%)', new ConeGeometry(radius, height, segments));
        }
      },
      shapeCylinder: {
        create: function() {
          var radiusTop = 4;
          var radiusBottom = 4;
          var height = 8;
          var radialSegments = 24;
          return addShape('hsl(170,100%,40%)', new CylinderGeometry(radiusTop, radiusBottom, height, radialSegments));
        }
      },
      shapeSphere: {
        create: function() {
          var radius = 5;
          var widthSegments = 24;
          var heightSegments = 16;
          return addShape('hsl(180,100%,40%)', new SphereGeometry(radius, widthSegments, heightSegments));
        }
      },
      shapeFrustum: {
        create: function() {
          var width = 8;
          var height = 8;
          var depth = 8;
          var geometry = new BoxGeometry(width, height, depth);
          var perspMat = new Matrix4();
          perspMat.makePerspective(-3, 3, -3, 3, 4, 12);
          var inMat = new Matrix4();
          inMat.makeTranslation(0, 0, 8);

          var mat = new Matrix4();
          mat.multiply(perspMat);
          mat.multiply(inMat);

          geometry.applyMatrix4(mat);
          geometry.computeBoundingBox();
          geometry.center();
          geometry.scale(3, 3, 3);
          geometry.rotateY(Math.PI);
          geometry.computeVertexNormals();

          return addShape('hsl(190,100%,40%)', geometry);
        }
      }
    });
  }

  public static function new() {
    main();
  }
}