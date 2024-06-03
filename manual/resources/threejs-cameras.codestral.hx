import js.Browser.document;
import js.html.Element;
import js.Three;
import threejsLessonUtils from 'threejs-lesson-utils';

class Main {
    public static function main() {
        var diagrams = new haxe.ds.StringMap<Dynamic>();

        diagrams.set("shapeCube", {
            create: function() {
                var width:Float = 8;
                var height:Float = 8;
                var depth:Float = 8;
                return addShape("hsl(150,100%,40%)", new Three.BoxGeometry(width, height, depth));
            }
        });

        diagrams.set("shapeCone", {
            create: function() {
                var radius:Float = 6;
                var height:Float = 8;
                var segments:Int = 24;
                return addShape("hsl(160,100%,40%)", new Three.ConeGeometry(radius, height, segments));
            }
        });

        diagrams.set("shapeCylinder", {
            create: function() {
                var radiusTop:Float = 4;
                var radiusBottom:Float = 4;
                var height:Float = 8;
                var radialSegments:Int = 24;
                return addShape("hsl(170,100%,40%)", new Three.CylinderGeometry(radiusTop, radiusBottom, height, radialSegments));
            }
        });

        diagrams.set("shapeSphere", {
            create: function() {
                var radius:Float = 5;
                var widthSegments:Int = 24;
                var heightSegments:Int = 16;
                return addShape("hsl(180,100%,40%)", new Three.SphereGeometry(radius, widthSegments, heightSegments));
            }
        });

        diagrams.set("shapeFrustum", {
            create: function() {
                var width:Float = 8;
                var height:Float = 8;
                var depth:Float = 8;
                var geometry = new Three.BoxGeometry(width, height, depth);
                var perspMat = new Three.Matrix4();
                perspMat.makePerspective(-3, 3, -3, 3, 4, 12);
                var inMat = new Three.Matrix4();
                inMat.makeTranslation(0, 0, 8);

                var mat = new Three.Matrix4();
                mat.multiply(perspMat);
                mat.multiply(inMat);

                geometry.applyMatrix4(mat);
                geometry.computeBoundingBox();
                geometry.center();
                geometry.scale(3, 3, 3);
                geometry.rotateY(Math.PI);
                geometry.computeVertexNormals();

                return addShape("hsl(190,100%,40%)", geometry);
            }
        });

        threejsLessonUtils.addDiagrams(diagrams);
    }

    private static function addShape(color:String, geometry:Three.Geometry) {
        var material = new Three.MeshPhongMaterial({color: color});
        return new Three.Mesh(geometry, material);
    }
}