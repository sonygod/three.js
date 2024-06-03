package three.js.manual.resources;

import three.js.*;

class ThreejsMaterials {
    static function makeSphere(widthDivisions:Int, heightDivisions:Int) {
        var radius:Float = 7;
        return new SphereGeometry(radius, widthDivisions, heightDivisions);
    }

    static var highPolySphereGeometry = makeSphere(100, 50);
    static var lowPolySphereGeometry = makeSphere(12, 9);

    static function smoothOrFlat(flatShading:Bool, radius:Float = 7) {
        var widthDivisions:Int = 12;
        var heightDivisions:Int = 9;
        var geometry = new SphereGeometry(radius, widthDivisions, heightDivisions);
        var material = new MeshPhongMaterial({
            flatShading: flatShading,
            color: 'hsl(300,50%,50%)'
        });
        return new Mesh(geometry, material);
    }

    static function basicLambertPhongExample(MaterialCtor:Class<Material>, lowPoly:Bool, ?params:Dynamic) {
        var geometry = lowPoly ? lowPolySphereGeometry : highPolySphereGeometry;
        var material = new MaterialCtor({
            color: 'hsl(210,50%,50%)',
            ...params
        });
        return {
            obj3D: new Mesh(geometry, material),
            trackball: lowPoly
        };
    }

    static function sideExample(side:Int) {
        var base = new Object3D();
        var size:Float = 6;
        var geometry = new PlaneGeometry(size, size);
        [
            { position: [-1, 0, 0], up: [0, 1, 0] },
            { position: [1, 0, 0], up: [0, -1, 0] },
            { position: [0, -1, 0], up: [0, 0, -1] },
            { position: [0, 1, 0], up: [0, 0, 1] },
            { position: [0, 0, -1], up: [1, 0, 0] },
            { position: [0, 0, 1], up: [-1, 0, 0] },
        ].forEach((settings, ndx) -> {
            var material = new MeshBasicMaterial({ side: side });
            material.color.setHSL(ndx / 6, .5, .5);
            var mesh = new Mesh(geometry, material);
            mesh.up.set(settings.up);
            mesh.lookAt(settings.position);
            mesh.position.set(settings.position).multiplyScalar(size * .75);
            base.add(mesh);
        });
        return base;
    }

    static function makeStandardPhysicalMaterialGrid(elem:HtmlElement, physical:Bool, update:Void->Void) {
        var numMetal:Int = 5;
        var numRough:Int = 7;
        var meshes:Array<Array<Mesh>> = [];
        var MatCtor:Class<Material> = physical ? MeshPhysicalMaterial : MeshStandardMaterial;
        var color:String = physical ? 'hsl(160,50%,50%)' : 'hsl(140,50%,50%)';
        for (m in 0...numMetal) {
            var row:Array<Mesh> = [];
            for (r in 0...numRough) {
                var material = new MatCtor({
                    color: color,
                    roughness: r / (numRough - 1),
                    metalness: 1 - m / (numMetal - 1),
                });
                var mesh = new Mesh(highPolySphereGeometry, material);
                row.push(mesh);
            }
            meshes.push(row);
        }
        return {
            obj3D: null,
            trackball: false,
            render: function(renderInfo:RenderInfo) {
                var { camera, scene, renderer } = renderInfo;
                var rect = elem.getBoundingClientRect();

                var width:Float = (rect.right - rect.left) * renderInfo.pixelRatio;
                var height:Float = (rect.bottom - rect.top) * renderInfo.pixelRatio;
                var left:Float = rect.left * renderInfo.pixelRatio;
                var bottom:Float = (renderer.domElement.clientHeight - rect.bottom) * renderInfo.pixelRatio;

                var cellSize:Float = Math.min(width / numRough, height / numMetal) | 0;
                var xOff:Float = (width - cellSize * numRough) / 2;
                var yOff:Float = (height - cellSize * numMetal) / 2;

                camera.aspect = 1;
                camera.updateProjectionMatrix();

                if (update != null) {
                    update();
                }

                for (m in 0...numMetal) {
                    for (r in 0...numRough) {
                        var x:Float = left + xOff + r * cellSize;
                        var y:Float = bottom + yOff + m * cellSize;
                        renderer.setViewport(x, y, cellSize, cellSize);
                        renderer.setScissor(x, y, cellSize, cellSize);
                        var mesh = meshes[m][r];
                        scene.add(mesh);
                        renderer.render(scene, camera);
                        scene.remove(mesh);
                    }
                }
            },
        };
    }

    static function addDiagrams(diagrams:Dynamic) {
        ThreejsLessonUtils.addDiagrams(diagrams);
    }

    static function main() {
        addDiagrams({
            smoothShading: {
                create: () -> smoothOrFlat(false)
            },
            flatShading: {
                create: () -> smoothOrFlat(true)
            },
            MeshBasicMaterial: {
                create: () -> basicLambertPhongExample(MeshBasicMaterial)
            },
            MeshLambertMaterial: {
                create: () -> basicLambertPhongExample(MeshLambertMaterial)
            },
            MeshPhongMaterial: {
                create: () -> basicLambertPhongExample(MeshPhongMaterial)
            },
            MeshBasicMaterialLowPoly: {
                create: () -> basicLambertPhongExample(MeshBasicMaterial, true)
            },
            MeshLambertMaterialLowPoly: {
                create: () -> basicLambertPhongExample(MeshLambertMaterial, true)
            },
            MeshPhongMaterialLowPoly: {
                create: () -> basicLambertPhongExample(MeshPhongMaterial, true)
            },
            MeshPhongMaterialShininess0: {
                create: () -> basicLambertPhongExample(MeshPhongMaterial, false, {
                    color: 'red',
                    shininess: 0
                })
            },
            MeshPhongMaterialShininess30: {
                create: () -> basicLambertPhongExample(MeshPhongMaterial, false, {
                    color: 'red',
                    shininess: 30
                })
            },
            MeshPhongMaterialShininess150: {
                create: () -> basicLambertPhongExample(MeshPhongMaterial, false, {
                    color: 'red',
                    shininess: 150
                })
            },
            MeshBasicMaterialCompare: {
                create: () -> basicLambertPhongExample(MeshBasicMaterial, false, {
                    color: 'purple'
                })
            },
            MeshLambertMaterialCompare: {
                create: () -> basicLambertPhongExample(MeshLambertMaterial, false, {
                    color: 'black',
                    emissive: 'purple'
                })
            },
            MeshPhongMaterialCompare: {
                create: () -> basicLambertPhongExample(MeshPhongMaterial, false, {
                    color: 'black',
                    emissive: 'purple',
                    shininess: 0
                })
            },
            MeshToonMaterial: {
                create: () -> basicLambertPhongExample(MeshToonMaterial)
            },
            MeshStandardMaterial: {
                create: (props) -> makeStandardPhysicalMaterialGrid(props.renderInfo.elem, false)
            },
            MeshPhysicalMaterial: {
                create: (props) -> {
                    var settings = {
                        clearcoat: .5,
                        clearcoatRoughness: 0
                    };

                    var addElem = (parent, type:String, style:Dynamic) -> {
                        var elem:HtmlElement = document.createElement(type);
                        for (field in style) {
                            Reflect.setField(elem.style, field, style[field]);
                        }
                        parent.appendChild(elem);
                        return elem;
                    };

                    var addRange = (elem:HtmlElement, obj:Dynamic, prop:String, min:Float, max:Float) -> {
                        var outer:HtmlElement = addElem(elem, 'div', {
                            width: '100%',
                            textAlign: 'center',
                            fontFamily: 'monospace'
                        });

                        var div:HtmlElement = addElem(outer, 'div', {
                            textAlign: 'left',
                            display: 'inline-block'
                        });

                        var label:HtmlElement = addElem(div, 'label', {
                            display: 'inline-block',
                            width: '12em'
                        });
                        label.textContent = prop;

                        var num:HtmlElement = addElem(div, 'div', {
                            display: 'inline-block',
                            width: '3em'
                        });

                        var updateNum = () -> {
                            num.textContent = obj[prop].toFixed(2);
                        };

                        updateNum();

                        var input:HtmlInputElement = addElem(div, 'input', {
                            type: 'range',
                            min: '0',
                            max: '100',
                            value: Math.floor((obj[prop] - min) / (max - min) * 100).toString()
                        });
                        input.addEventListener('input', () -> {
                            obj[prop] = min + (max - min) * input.value / 100;
                            updateNum();
                        });

                    };

                    var { elem } = props.renderInfo;
                    addRange(elem, settings, 'clearcoat', 0, 1);
                    addRange(elem, settings, 'clearcoatRoughness', 0, 1);
                    var area:HtmlElement = addElem(elem, 'div', {
                        width: '100%',
                        height: '400px'
                    });

                    return makeStandardPhysicalMaterialGrid(area, true, (meshes) -> {
                        for (row in meshes) {
                            for (mesh in row) {
                                mesh.material.clearcoat = settings.clearcoat;
                                mesh.material.clearcoatRoughness = settings.clearcoatRoughness;
                            }
                        }
                    });
                }
            },
            MeshDepthMaterial: {
                create: (props) -> {
                    var { camera } = props;
                    var radius:Float = 4;
                    var tube:Float = 1.5;
                    var radialSegments:Int = 8;
                    var tubularSegments:Int = 64;
                    var p:Int = 2;
                    var q:Int = 3;
                    var geometry = new TorusKnotGeometry(radius, tube, tubularSegments, radialSegments, p, q);
                    var material = new MeshDepthMaterial();
                    camera.near = 7;
                    camera.far = 20;
                    return new Mesh(geometry, material);
                }
            },
            MeshNormalMaterial: {
                create: () -> {
                    var radius:Float = 4;
                    var tube:Float = 1.5;
                    var radialSegments:Int = 8;
                    var tubularSegments:Int = 64;
                    var p:Int = 2;
                    var q:Int = 3;
                    var geometry = new TorusKnotGeometry(radius, tube, tubularSegments, radialSegments, p, q);
                    var material = new MeshNormalMaterial();
                    return new Mesh(geometry, material);
                }
            },
            sideDefault: {
                create: () -> sideExample(THREE.FrontSide)
            },
            sideDouble: {
                create: () -> sideExample(THREE.DoubleSide)
            }
        });
    }
}