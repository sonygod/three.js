package three.js.manual.resources;

import three.js.Three;
import three.js.examples.jsm.controls.OrbitControls;
import threejsLessonUtils;

class ThreejsLights {
    static function makeCheckerTexture(repeats:Int):Three.Texture {
        var data = new Uint8Array([
            0x88, 0x88, 0x88, 0xFF, 0xCC, 0xCC, 0xCC, 0xFF,
            0xCC, 0xCC, 0xCC, 0xFF, 0x88, 0x88, 0x88, 0xFF
        ]);
        var width = 2;
        var height = 2;
        var texture = new Three.DataTexture(data, width, height);
        texture.needsUpdate = true;
        texture.wrapS = Three.RepeatWrapping;
        texture.wrapT = Three.RepeatWrapping;
        texture.repeat.set(repeats / 2, repeats / 2);
        return texture;
    }

    static function makeScene():Dynamic {
        var cubeSize = 4;
        var cubeGeo = new Three.BoxGeometry(cubeSize, cubeSize, cubeSize);
        var cubeMat = new Three.MeshPhongMaterial({color: 0x8AC});

        var sphereRadius = 3;
        var sphereWidthDivisions = 32;
        var sphereHeightDivisions = 16;
        var sphereGeo = new Three.SphereGeometry(sphereRadius, sphereWidthDivisions, sphereHeightDivisions);
        var sphereMat = new Three.MeshPhongMaterial({color: 0xCA8});

        var planeSize = 40;
        var planeGeo = new Three.PlaneGeometry(planeSize, planeSize);
        var planeMat = new Three.MeshPhongMaterial({
            map: makeCheckerTexture(planeSize),
            side: Three.DoubleSide,
        });

        return function (renderInfo:Dynamic) {
            var scene = renderInfo.scene;
            var camera = renderInfo.camera;
            var elem = renderInfo.elem;
            var controls = new OrbitControls(camera, elem);
            controls.enableDamping = true;
            controls.enablePanning = false;
            scene.background = new Three.Color(0x000000);
            {
                var mesh = new Three.Mesh(cubeGeo, cubeMat);
                mesh.position.set(cubeSize + 1, cubeSize / 2, -cubeSize - 1);
                scene.add(mesh);
            }
            {
                var mesh = new Three.Mesh(sphereGeo, sphereMat);
                mesh.position.set(-sphereRadius - 1, sphereRadius + 2, -sphereRadius + 1);
                scene.add(mesh);
            }
            {
                var mesh = new Three.Mesh(planeGeo, planeMat);
                mesh.rotation.x = Math.PI * -0.5;
                scene.add(mesh);
            }
            return {
                trackball: false,
                lights: false,
                update: function () {
                    controls.update();
                },
            };
        };
    }

    static function main() {
        threejsLessonUtils.addDiagrams({
            directionalOnly: {
                create: function (props:Dynamic) {
                    var scene = props.scene;
                    var renderInfo = props.renderInfo;
                    var result = makeScene()(renderInfo);
                    {
                        var light = new Three.DirectionalLight(0xFFFFFF, 1);
                        light.position.set(5, 10, 0);
                        scene.add(light);
                    }
                    {
                        var light = new Three.AmbientLight(0xFFFFFF, 0.6);
                        scene.add(light);
                    }
                    return result;
                },
            },
            directionalPlusHemisphere: {
                create: function (props: Dynamic) {
                    var scene = props.scene;
                    var renderInfo = props.renderInfo;
                    var result = makeScene()(renderInfo);
                    {
                        var light = new Three.DirectionalLight(0xFFFFFF, 1);
                        light.position.set(5, 10, 0);
                        scene.add(light);
                    }
                    {
                        var skyColor = 0xB1E1FF; // light blue
                        var groundColor = 0xB97A20; // brownish orange
                        var intensity = 0.6;
                        var light = new Three.HemisphereLight(skyColor, groundColor, intensity);
                        scene.add(light);
                    }
                    return result;
                },
            },
        });
    }
}