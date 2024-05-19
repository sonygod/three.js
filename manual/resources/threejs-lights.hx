import three.js.*;

class ThreeJsLights {
    static function makeCheckerTexture(repeats:Int):Texture {
        var data:Array<Int> = [
            0x88, 0x88, 0x88, 0xFF,
            0xCC, 0xCC, 0xCC, 0xFF,
            0xCC, 0xCC, 0xCC, 0xFF,
            0x88, 0x88, 0x88, 0xFF
        ];
        var width:Int = 2;
        var height:Int = 2;
        var texture:DataTexture = new DataTexture(cast data, width, height);
        texture.needsUpdate = true;
        texture.wrapS = RepeatWrapping;
        texture.wrapT = RepeatWrapping;
        texture.repeat.set(repeats / 2, repeats / 2);
        return texture;
    }

    static function makeScene():Void->{
        trackball:Bool,
        lights:Bool,
        update:Void->Void
    } {
        var cubeSize:Float = 4;
        var cubeGeo:BoxGeometry = new BoxGeometry(cubeSize, cubeSize, cubeSize);
        var cubeMat:MeshPhongMaterial = new MeshPhongMaterial({ color: 0x8AC });

        var sphereRadius:Float = 3;
        var sphereWidthDivisions:Int = 32;
        var sphereHeightDivisions:Int = 16;
        var sphereGeo:SphereGeometry = new SphereGeometry(sphereRadius, sphereWidthDivisions, sphereHeightDivisions);
        var sphereMat:MeshPhongMaterial = new MeshPhongMaterial({ color: 0xCA8 });

        var planeSize:Float = 40;
        var planeGeo:PlaneGeometry = new PlaneGeometry(planeSize, planeSize);
        var planeMat:MeshPhongMaterial = new MeshPhongMaterial({
            map: makeCheckerTexture(planeSize),
            side: DoubleSide
        });

        return function(renderInfo:Any) {
            var scene:Scene = renderInfo.scene;
            var camera:Camera = renderInfo.camera;
            var elem:HtmlElement = renderInfo.elem;
            var controls:OrbitControls = new OrbitControls(camera, elem);
            controls.enableDamping = true;
            controls.enablePanning = false;
            scene.background = new Color(0x000000);

            {
                var mesh:Mesh = new Mesh(cubeGeo, cubeMat);
                mesh.position.set(cubeSize + 1, cubeSize / 2, -cubeSize - 1);
                scene.add(mesh);
            }

            {
                var mesh:Mesh = new Mesh(sphereGeo, sphereMat);
                mesh.position.set(-sphereRadius - 1, sphereRadius + 2, -sphereRadius + 1);
                scene.add(mesh);
            }

            {
                var mesh:Mesh = new Mesh(planeGeo, planeMat);
                mesh.rotation.x = Math.PI * -0.5;
                scene.add(mesh);
            }

            return {
                trackball: false,
                lights: false,
                update: function() {
                    controls.update();
                }
            };
        };
    }

    public static function main() {
        threejsLessonUtils.addDiagrams({
            directionalOnly: {
                create: function(props:Any) {
                    var scene:Scene = props.scene;
                    var renderInfo:Any = props.renderInfo;
                    var result:Any = makeScene()(renderInfo);
                    {
                        var light:DirectionalLight = new DirectionalLight(0xFFFFFF, 1);
                        light.position.set(5, 10, 0);
                        scene.add(light);
                    }

                    {
                        var light:AmbientLight = new AmbientLight(0xFFFFFF, 0.6);
                        scene.add(light);
                    }

                    return result;
                }
            },
            directionalPlusHemisphere: {
                create: function(props:Any) {
                    var scene:Scene = props.scene;
                    var renderInfo:Any = props.renderInfo;
                    var result:Any = makeScene()(renderInfo);
                    {
                        var light:DirectionalLight = new DirectionalLight(0xFFFFFF, 1);
                        light.position.set(5, 10, 0);
                        scene.add(light);
                    }

                    {
                        var skyColor:Int = 0xB1E1FF; // light blue
                        var groundColor:Int = 0xB97A20; // brownish orange
                        var intensity:Float = 0.6;
                        var light:HemisphereLight = new HemisphereLight(skyColor, groundColor, intensity);
                        scene.add(light);
                    }

                    return result;
                }
            }
        });
    }
}