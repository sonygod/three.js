package three.js.manual.resources;

import three.js.*;

class ThreejsFog {
    static var darkColors = {
        background: '#333'
    }
    static var lightColors = {
        background: '#FFF'
    }
    static var darkMatcher = js.Browser.window.matchMedia('(prefers-color-scheme: dark)');

    static function fogExample(scene:Scene, fog:Fog, update:Void->Void) {
        scene.fog = fog;
        var width = 4;
        var height = 3;
        var depth = 10;
        var geometry = new BoxGeometry(width, height, depth);
        var material = new MeshPhongMaterial({color: 'hsl(130,50%,50%)'});
        return {
            obj3D: new Mesh(geometry, material),
            update: update
        };
    }

    static function houseScene(props:{scene:Scene, camera:Camera}, fogInHouse:Bool) {
        var scene = props.scene;
        scene.background = new Color('#FFF');
        props.camera.far = 200;
        var loader = new GLTFLoader();
        var settings = {
            shininess: 0,
            roughness: 1,
            metalness: 0
        };
        loader.load('/manual/examples/resources/models/simple_house_scene/scene.gltf', (gltf) -> {
            var hackGeometry = new CircleGeometry(0.5, 32);
            var box = new Box3();
            var size = new Vector3();
            var center = new Vector3();
            var materials = new Set<Material>();
            gltf.scene.traverse((node) -> {
                var material = node.material;
                if (material) {
                    // hack in the bottom of the trees since I don't have
                    // the model file
                    if (node.name == 'mesh_11' || node.name == 'mesh_6') {
                        node.updateWorldMatrix(true, false);
                        box.setFromObject(node);
                        box.getSize(size);
                        box.getCenter(center);
                        var hackMesh = new Mesh(hackGeometry, node.material);
                        scene.add(hackMesh);
                        hackMesh.position.copy(center);
                        hackMesh.rotation.x = Math.PI * 0.5;
                        hackMesh.position.y -= size.y / 2;
                        hackMesh.scale.set(size.x, size.z, 1);
                    }
                    (Array.isArray(material) ? material : [material]).forEach((material) -> {
                        if (!materials.has(material)) {
                            materials.add(material);
                            for (field in Reflect.fields(settings)) {
                                if (Reflect.hasField(material, field)) {
                                    Reflect.setField(material, field, Reflect.field(settings, field));
                                }
                            }
                            if (!fogInHouse && material.name.startsWith('fogless')) {
                                material.fog = false;
                            }
                        }
                    });
                }
            });
            scene.add(gltf.scene);
        });
        props.camera.fov = 45;
        props.camera.position.set(0.4, 1, 1.7);
        props.camera.lookAt(1, 1, 0.7);
        var color = 0xFFFFFF;
        var near = 1.5;
        var far = 5;
        scene.fog = new Fog(color, near, far);
        var light = new PointLight(0xFFFFFF, 1);
        light.position.copy(props.camera.position);
        light.position.y += 0.2;
        scene.add(light);
        var target = [1, 1, 0.7];
        return {
            trackball: false,
            obj3D: new Object3D(),
            update: (time:Float) -> {
                props.camera.lookAt(target[0] + Math.sin(time * 0.25) * 0.5, target[1], target[2]);
            }
        };
    }

    static function createLightDarkFogUpdater(fog:Fog) {
        return function() {
            var isDarkMode = darkMatcher.matches;
            var colors = isDarkMode ? darkColors : lightColors;
            fog.color.set(colors.background);
        };
    }

    static function main() {
        threejsLessonUtils.addDiagrams({
            fog: {
                create: (props:{scene:Scene}) -> {
                    var scene = props.scene;
                    var color = 0xFFFFFF;
                    var near = 12;
                    var far = 18;
                    var fog = new Fog(color, near, far);
                    return fogExample(scene, fog, createLightDarkFogUpdater(fog));
                }
            },
            fogExp2: {
                create: (props:{scene:Scene}) -> {
                    var scene = props.scene;
                    var color = 0xFFFFFF;
                    var density = 0.1;
                    var fog = new FogExp2(color, density);
                    return fogExample(scene, fog, createLightDarkFogUpdater(fog));
                }
            },
            fogBlueBackgroundRed: {
                create: (props:{scene:Scene}) -> {
                    var scene = props.scene;
                    scene.background = new Color('#F00');
                    var color = '#00F';
                    var near = 12;
                    var far = 18;
                    return fogExample(scene, new Fog(color, near, far));
                }
            },
            fogBlueBackgroundBlue: {
                create: (props:{scene:Scene}) -> {
                    var scene = props.scene;
                    scene.background = new Color('#00F');
                    var color = '#00F';
                    var near = 12;
                    var far = 18;
                    return fogExample(scene, new Fog(color, near, far));
                }
            },
            fogHouseAll: {
                create: (props:{scene:Scene, camera:Camera}) -> {
                    return houseScene(props, true);
                }
            },
            fogHouseInsideNoFog: {
                create: (props:{scene:Scene, camera:Camera}) -> {
                    return houseScene(props, false);
                }
            }
        });
    }
}