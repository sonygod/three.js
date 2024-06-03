package three;

import three.js.Three;
import three.loaders.GLTFLoader;
import threejsLessonUtils.ThreejsLessonUtils;

class FogExample {
    static function main() {
        // Colors
        var darkColors = { background: "#333" };
        var lightColors = { background: "#FFF" };
        var darkMatcher = js.Browser.window.matchMedia("(prefers-color-scheme: dark)");

        // Fog example
        function fogExample(scene:three.Scene, fog:three.Fog, update: Void->Void) {
            scene.fog = fog;
            var width = 4;
            var height = 3;
            var depth = 10;
            var geometry = new three.BoxGeometry(width, height, depth);
            var material = new three.MeshPhongMaterial({ color: "hsl(130,50%,50%)" });
            return {
                obj3D: new three.Mesh(geometry, material),
                update: update
            };
        }

        // House scene
        function houseScene(props: { scene: three.Scene, camera: three.Camera }, fogInHouse: Bool) {
            var { scene, camera } = props;
            scene.background = new three.Color("#FFF");
            camera.far = 200;
            var loader = new GLTFLoader();
            var settings = {
                shininess: 0,
                roughness: 1,
                metalness: 0
            };
            loader.load("/manual/examples/resources/models/simple_house_scene/scene.gltf", (gltf) => {
                var hackGeometry = new three.CircleGeometry(0.5, 32);
                var box = new three.Box3();
                var size = new three.Vector3();
                var center = new three.Vector3();
                var materials = new Set();
                gltf.scene.traverse((node) => {
                    var material = node.material;
                    if (material) {
                        if (node.name == "mesh_11" || node.name == "mesh_6") {
                            node.updateWorldMatrix(true, false);
                            box.setFromObject(node);
                            box.getSize(size);
                            box.getCenter(center);
                            var hackMesh = new three.Mesh(hackGeometry, node.material);
                            scene.add(hackMesh);
                            hackMesh.position.copy(center);
                            hackMesh.rotation.x = Math.PI * 0.5;
                            hackMesh.position.y -= size.y / 2;
                            hackMesh.scale.set(size.x, size.z, 1);
                        }
                        (material instanceof Array ? material : [material]).forEach((material) => {
                            if (!materials.has(material)) {
                                materials.add(material);
                                for (key => value in settings) {
                                    if (material[key] != undefined) {
                                        material[key] = value;
                                    }
                                }
                                if (!fogInHouse && material.name.startsWith("fogless")) {
                                    material.fog = false;
                                }
                            }
                        });
                    }
                });
                scene.add(gltf.scene);
            });
            camera.fov = 45;
            camera.position.set(0.4, 1, 1.7);
            camera.lookAt(1, 1, 0.7);

            var color = 0xFFFFFF;
            var near = 1.5;
            var far = 5;
            scene.fog = new three.Fog(color, near, far);

            var light = new three.PointLight(0xFFFFFF, 1);
            light.position.copy(camera.position);
            light.position.y += 0.2;
            scene.add(light);

            var target = [1, 1, 0.7];
            return {
                trackball: false,
                obj3D: new three.Object3D(),
                update: (time) => {
                    camera.lookAt(target[0] + Math.sin(time * 0.25) * 0.5, target[1], target[2]);
                }
            };
        }

        // Create light/dark fog updater
        function createLightDarkFogUpdater(fog: three.Fog) {
            return function() {
                var isDarkMode = darkMatcher.matches;
                var colors = isDarkMode ? darkColors : lightColors;
                fog.color.set(colors.background);
            };
        }

        // Add diagrams
        ThreejsLessonUtils.addDiagrams({
            "fog": {
                create: (props) => {
                    var { scene } = props;
                    var color = 0xFFFFFF;
                    var near = 12;
                    var far = 18;
                    var fog = new three.Fog(color, near, far);
                    return fogExample(scene, fog, createLightDarkFogUpdater(fog));
                }
            },
            "fogExp2": {
                create: (props) => {
                    var { scene } = props;
                    var color = 0xFFFFFF;
                    var density = 0.1;
                    var fog = new three.FogExp2(color, density);
                    return fogExample(scene, fog, createLightDarkFogUpdater(fog));
                }
            },
            "fogBlueBackgroundRed": {
                create: (props) => {
                    var { scene } = props;
                    scene.background = new three.Color("#F00");
                    var color = "#00F";
                    var near = 12;
                    var far = 18;
                    return fogExample(scene, new three.Fog(color, near, far));
                }
            },
            "fogBlueBackgroundBlue": {
                create: (props) => {
                    var { scene } = props;
                    scene.background = new three.Color("#00F");
                    var color = "#00F";
                    var near = 12;
                    var far = 18;
                    return fogExample(scene, new three.Fog(color, near, far));
                }
            },
            "fogHouseAll": {
                create: (props) => {
                    return houseScene(props, true);
                }
            },
            "fogHouseInsideNoFog": {
                create: (props) => {
                    return houseScene(props, false);
                }
            }
        });
    }
}