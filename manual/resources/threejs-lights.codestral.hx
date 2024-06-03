import three.THREE;
import three.controls.OrbitControls;
import threejsLessonUtils.ThreejsLessonUtils;

class LightScript {
    public static function makeCheckerTexture(repeats:Int):THREE.DataTexture {
        var data:haxe.io.Bytes = haxe.io.Bytes.ofData([
            0x88, 0x88, 0x88, 0xFF, 0xCC, 0xCC, 0xCC, 0xFF,
            0xCC, 0xCC, 0xCC, 0xFF, 0x88, 0x88, 0x88, 0xFF
        ]);
        var width:Int = 2;
        var height:Int = 2;
        var texture:THREE.DataTexture = new THREE.DataTexture(data, width, height);
        texture.needsUpdate = true;
        texture.wrapS = THREE.RepeatWrapping;
        texture.wrapT = THREE.RepeatWrapping;
        texture.repeat.set(repeats / 2, repeats / 2);
        return texture;
    }

    public static function makeScene(renderInfo:RenderInfo):Function {
        var cubeSize:Float = 4;
        var cubeGeo:THREE.BoxGeometry = new THREE.BoxGeometry(cubeSize, cubeSize, cubeSize);
        var cubeMat:THREE.MeshPhongMaterial = new THREE.MeshPhongMaterial({ color: 0x8AC });

        var sphereRadius:Float = 3;
        var sphereWidthDivisions:Int = 32;
        var sphereHeightDivisions:Int = 16;
        var sphereGeo:THREE.SphereGeometry = new THREE.SphereGeometry(sphereRadius, sphereWidthDivisions, sphereHeightDivisions);
        var sphereMat:THREE.MeshPhongMaterial = new THREE.MeshPhongMaterial({ color: 0xCA8 });

        var planeSize:Float = 40;
        var planeGeo:THREE.PlaneGeometry = new THREE.PlaneGeometry(planeSize, planeSize);
        var planeMat:THREE.MeshPhongMaterial = new THREE.MeshPhongMaterial({
            map: makeCheckerTexture(planeSize),
            side: THREE.DoubleSide,
        });

        return function ():RenderResult {
            var scene:THREE.Scene = renderInfo.scene;
            var camera:THREE.Camera = renderInfo.camera;
            var elem:Element = renderInfo.elem;
            var controls:OrbitControls = new OrbitControls(camera, elem);
            controls.enableDamping = true;
            controls.enablePanning = false;
            scene.background = new THREE.Color("black");

            var mesh:THREE.Mesh = new THREE.Mesh(cubeGeo, cubeMat);
            mesh.position.set(cubeSize + 1, cubeSize / 2, -cubeSize - 1);
            scene.add(mesh);

            mesh = new THREE.Mesh(sphereGeo, sphereMat);
            mesh.position.set(-sphereRadius - 1, sphereRadius + 2, -sphereRadius + 1);
            scene.add(mesh);

            mesh = new THREE.Mesh(planeGeo, planeMat);
            mesh.rotation.x = Math.PI * -.5;
            scene.add(mesh);

            return {
                trackball: false,
                lights: false,
                update: function() {
                    controls.update();
                },
            };
        };
    }

    public static function main() {
        ThreejsLessonUtils.addDiagrams({
            directionalOnly: {
                create: function(props:Dynamic) {
                    var scene:THREE.Scene = props.scene;
                    var renderInfo:RenderInfo = props.renderInfo;
                    var result:RenderResult = makeScene(renderInfo)();

                    var light:THREE.DirectionalLight = new THREE.DirectionalLight(0xFFFFFF, 1);
                    light.position.set(5, 10, 0);
                    scene.add(light);

                    light = new THREE.AmbientLight(0xFFFFFF, .6);
                    scene.add(light);

                    return result;
                },
            },
            directionalPlusHemisphere: {
                create: function(props:Dynamic) {
                    var scene:THREE.Scene = props.scene;
                    var renderInfo:RenderInfo = props.renderInfo;
                    var result:RenderResult = makeScene(renderInfo)();

                    var light:THREE.DirectionalLight = new THREE.DirectionalLight(0xFFFFFF, 1);
                    light.position.set(5, 10, 0);
                    scene.add(light);

                    var skyColor:Int = 0xB1E1FF; // light blue
                    var groundColor:Int = 0xB97A20; // brownish orange
                    var intensity:Float = .6;
                    light = new THREE.HemisphereLight(skyColor, groundColor, intensity);
                    scene.add(light);

                    return result;
                },
            },
        });
    }
}