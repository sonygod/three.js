import three.*;
import three.loaders.GLTFLoader;
import threejsLessonUtils.ThreejsLessonUtils;

class FogExample {
    static function main() {
        var darkColors = {
            background: 0x333333,
        };
        var lightColors = {
            background: 0xFFFFFF,
        };
        var darkMatcher = js.Browser.window.matchMedia('(prefers-color-scheme: dark)');

        function fogExample(scene:Scene, fog:Fog, update:Dynamic):Dynamic {
            scene.fog = fog;
            var width = 4;
            var height = 3;
            var depth = 10;
            var geometry = new THREE.BoxGeometry(width, height, depth);
            var material = new THREE.MeshPhongMaterial({color: 'hsl(130,50%,50%)'});
            return {
                obj3D: new THREE.Mesh(geometry, material),
                update: update,
            };
        }

        function houseScene(props:Dynamic, fogInHouse:Bool):Dynamic {
            var scene:Scene = Reflect.field(props, "scene");
            var camera:Camera = Reflect.field(props, "camera");
            scene.background = new THREE.Color(0xFFFFFF);
            camera.far = 200;
            var loader = new GLTFLoader();
            var settings = {
                shininess: 0,
                roughness: 1,
                metalness: 0,
            };
            loader.load('/manual/examples/resources/models/simple_house_scene/scene.gltf', (gltf:Dynamic) => {
                // ... Rest of the code
            });
            // ... Rest of the code
        }

        function createLightDarkFogUpdater(fog:Fog):Dynamic {
            return function () {
                var isDarkMode = darkMatcher.matches;
                var colors = isDarkMode ? darkColors : lightColors;
                fog.color.set(colors.background);
            };
        }

        ThreejsLessonUtils.addDiagrams({
            fog: {
                create(props:Dynamic) {
                    var scene:Scene = Reflect.field(props, "scene");
                    var color = 0xFFFFFF;
                    var near = 12;
                    var far = 18;
                    var fog = new THREE.Fog(color, near, far);
                    return fogExample(scene, fog, createLightDarkFogUpdater(fog));
                },
            },
            // ... Rest of the code
        });
    }
}