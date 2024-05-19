package three;

import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.core.Matrix4;
import three.math.Vector3;
import three.math.Quaternion;

class BufferGeometryTests {
    public static function main() {
        var DegToRad = Math.PI / 180;

        function bufferAttributeEquals(a:BufferAttribute, b:BufferAttribute, tolerance:Float = 0.0001):Bool {
            if (a.count != b.count || a.itemSize != b.itemSize) {
                return false;
            }
            for (i in 0...a.count * a.itemSize) {
                var delta = a[i] - b[i];
                if (delta > tolerance) {
                    return false;
                }
            }
            return true;
        }

        function getBBForVertices(vertices:Array<Float>):Sphere {
            var geometry = new BufferGeometry();
            geometry.setAttribute('position', new BufferAttribute(new Float32Array(vertices), 3));
            geometry.computeBoundingBox();
            return geometry.boundingBox;
        }

        function getBSForVertices(vertices:Array<Float>):Sphere {
            var geometry = new BufferGeometry();
            geometry.setAttribute('position', new BufferAttribute(new Float32Array(vertices), 3));
            geometry.computeBoundingSphere();
            return geometry.boundingSphere;
        }

        function getNormalsForVertices(vertices:Array<Float>, assert:Dynamic):Array<Float> {
            var geometry = new BufferGeometry();
            geometry.setAttribute('position', new BufferAttribute(new Float32Array(vertices), 3));
            geometry.computeVertexNormals();
            return geometry.getAttribute('normal').array;
        }

        QUnit.module('Core', () => {
            QUnit.module('BufferGeometry', () => {
                QUnit.test('Extending', (assert:Dynamic) => {
                    var object = new BufferGeometry();
                    assert.ok(object instanceof EventDispatcher, 'BufferGeometry extends from EventDispatcher');
                });

                QUnit.test('Instancing', (assert:Dynamic) => {
                    var object = new BufferGeometry();
                    assert.ok(object, 'Can instantiate a BufferGeometry.');
                });

                // ... rest of the tests ...

                QUnit.test('computeVertexNormals', (assert:Dynamic) => {
                    var normals = getNormalsForVertices([-1, 0, 0, 1, 0, 0, 0, 1, 0], assert);
                    assert.ok(normals[0] == 0 && normals[1] == 0 && normals[2] == 1, 'first normal is pointing to screen since the the triangle was created counter clockwise');
                    // ... rest of the test ...
                });
            });
        });
    }
}