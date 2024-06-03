import js.Browser;
import js.html.InputElement;
import js.html.Window;
import three.js.*;
import threejsLessonUtils.ThreeJsLessonUtils;
import lilGui.GUI;

class DegRadHelper {
    public var obj:Dynamic;
    public var prop:String;

    public function new(obj:Dynamic, prop:String) {
        this.obj = obj;
        this.prop = prop;
    }

    public function get_value():Float {
        return THREE.Math.radToDeg(js.Reflect.field(obj, prop));
    }

    public function set_value(v:Float):Void {
        js.Reflect.setField(obj, prop, THREE.Math.degToRad(v));
    }
}

class Main {
    static function main() {
        ThreeJsLessonUtils.addDiagrams({
            scaleCenter: {
                create: function() {
                    return scaleCube(0);
                }
            },
            scalePositiveZ: {
                create: function() {
                    return scaleCube(0.5);
                }
            },
            lonLatPos: {
                create: function(info:Dynamic) {
                    var scene = info.scene;
                    var camera = info.camera;
                    var renderInfo = info.renderInfo;
                    var size = 10;
                    var divisions = 10;
                    var gridHelper = new THREE.GridHelper(size, divisions);
                    scene.add(gridHelper);

                    var geometry = new THREE.BoxGeometry(1, 1, 1);

                    var lonHelper = new THREE.Object3D();
                    scene.add(lonHelper);
                    var latHelper = new THREE.Object3D();
                    lonHelper.add(latHelper);
                    var positionHelper = new THREE.Object3D();
                    latHelper.add(positionHelper);

                    var lonMesh = new THREE.Mesh(geometry, new THREE.MeshBasicMaterial({ color: 0x00ff00 }));
                    lonMesh.scale.set(0.2, 1, 0.2);
                    lonHelper.add(lonMesh);

                    var latMesh = new THREE.Mesh(geometry, new THREE.MeshBasicMaterial({ color: 0x0000ff }));
                    latMesh.scale.set(1, 0.25, 0.25);
                    latHelper.add(latMesh);

                    var posMesh = new THREE.Mesh(new THREE.SphereGeometry(0.1, 24, 12), new THREE.MeshBasicMaterial({ color: 0xff0000 }));
                    posMesh.position.z = 1;
                    positionHelper.add(posMesh);

                    camera.position.set(1, 1.5, 1.5);
                    camera.lookAt(0, 0, 0);

                    var gui = new GUI({ autoPlace: false });
                    renderInfo.elem.appendChild(gui.domElement);
                    gui.add(new DegRadHelper(lonHelper.rotation, 'y'), 'value', -180, 180).name('lonHelper x rotation');
                    gui.add(new DegRadHelper(latHelper.rotation, 'x'), 'value', -90, 90).name('latHelper y rotation');

                    return {
                        trackball: false
                    };
                }
            }
        });
    }

    static function scaleCube(zOffset:Float):Dynamic {
        var root = new THREE.Object3D();

        var size = 3;
        var geometry = new THREE.BoxGeometry(size, size, size);
        geometry.applyMatrix4(new THREE.Matrix4().makeTranslation(0, 0, zOffset * size));
        var material = new THREE.MeshBasicMaterial({ color: 0xff0000 });
        var cube = new THREE.Mesh(geometry, material);
        root.add(cube);
        cube.add(new THREE.LineSegments(
            new THREE.EdgesGeometry(geometry),
            new THREE.LineBasicMaterial({ color: 0xffffff })
        ));

        var rotations = [[0, 0], [1, 0], [0, 1]];
        for (rotation in rotations) {
            var gridHelper = new THREE.GridHelper(10, 10);
            root.add(gridHelper);
            gridHelper.rotation.x = rotation[0] * Math.PI * 0.5;
            gridHelper.rotation.z = rotation[1] * Math.PI * 0.5;
        }

        return {
            obj3D: root,
            update: function(time:Float) {
                var s = THREE.MathUtils.lerp(0.5, 2, Math.sin(time) * 0.5 + 0.5);
                cube.scale.set(s, s, s);
            }
        };
    }
}