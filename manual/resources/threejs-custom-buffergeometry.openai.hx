package three.js.manual.resources;

import three.js.THREE;
import threejsLessonUtils.ThreejsLessonUtils;

class ThreejsCustomBufferGeometry {
    public function new() {
        var loader:THREE.TextureLoader = new THREE.TextureLoader();
        var texture:THREE.Texture = loader.load('/manual/examples/resources/images/star-light.png');
        texture.wrapS = THREE.RepeatWrapping;
        texture.wrapT = THREE.RepeatWrapping;
        texture.repeat.set(3, 1);

        function makeMesh(geometry:THREE.Geometry):THREE.Mesh {
            var material:THREE.MeshPhongMaterial = new THREE.MeshPhongMaterial({
                color: 'hsl(300,50%,50%)',
                side: THREE.DoubleSide,
                map: texture,
            });
            return new THREE.Mesh(geometry, material);
        }

        threejsLessonUtils.addDiagrams({
            geometryCylinder: {
                create: function() {
                    return new THREE.Object3D();
                },
            },
            bufferGeometryCylinder: {
                create: function() {
                    var numSegments:Int = 24;
                    var positions:Array<Float> = [];
                    var uvs:Array<Float> = [];
                    for (s in 0...numSegments + 1) {
                        var u:Float = s / numSegments;
                        var a:Float = u * Math.PI * 2;
                        var x:Float = Math.sin(a);
                        var z:Float = Math.cos(a);
                        positions.push(x, -1, z);
                        positions.push(x, 1, z);
                        uvs.push(u, 0);
                        uvs.push(u, 1);
                    }

                    var indices:Array<Int> = [];
                    for (s in 0...numSegments) {
                        var ndx:Int = s * 2;
                        indices.push(ndx, ndx + 2, ndx + 1);
                        indices.push(ndx + 1, ndx + 2, ndx + 3);
                    }

                    var positionNumComponents:Int = 3;
                    var uvNumComponents:Int = 2;
                    var geometry:THREE.BufferGeometry = new THREE.BufferGeometry();
                    geometry.setAttribute('position', new THREE.BufferAttribute(new Float32Array(positions), positionNumComponents));
                    geometry.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(uvs), uvNumComponents));

                    geometry.setIndex(indices);
                    geometry.computeVertexNormals();
                    geometry.scale(5, 5, 5);
                    return makeMesh(geometry);
                },
            },
        });
    }
}