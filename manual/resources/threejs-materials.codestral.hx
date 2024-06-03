import Three.js.THREE;
import Three.js.threejsLessonUtils;

class ThreeJSMaterials {
    static function makeSphere(widthDivisions: Int, heightDivisions: Int): THREE.SphereGeometry {
        var radius: Float = 7;
        return new THREE.SphereGeometry(radius, widthDivisions, heightDivisions);
    }

    static var highPolySphereGeometry: THREE.SphereGeometry = (function() {
        var widthDivisions: Int = 100;
        var heightDivisions: Int = 50;
        return makeSphere(widthDivisions, heightDivisions);
    })();

    static var lowPolySphereGeometry: THREE.SphereGeometry = (function() {
        var widthDivisions: Int = 12;
        var heightDivisions: Int = 9;
        return makeSphere(widthDivisions, heightDivisions);
    })();

    static function smoothOrFlat(flatShading: Bool, radius: Float = 7): THREE.Mesh {
        var widthDivisions: Int = 12;
        var heightDivisions: Int = 9;
        var geometry: THREE.SphereGeometry = new THREE.SphereGeometry(radius, widthDivisions, heightDivisions);
        var material: THREE.MeshPhongMaterial = new THREE.MeshPhongMaterial({
            flatShading: flatShading,
            color: 'hsl(300,50%,50%)'
        });
        return new THREE.Mesh(geometry, material);
    }

    static function basicLambertPhongExample(MaterialCtor: Class<THREE.Material>, lowPoly: Bool, params: Dynamic = null): Dynamic {
        var geometry: THREE.SphereGeometry = lowPoly ? lowPolySphereGeometry : highPolySphereGeometry;
        var material: THREE.Material = new MaterialCtor({
            color: 'hsl(210,50%,50%)',
            ...params
        });
        return {
            obj3D: new THREE.Mesh(geometry, material),
            trackball: lowPoly
        };
    }

    static function sideExample(side: Int): THREE.Object3D {
        var base: THREE.Object3D = new THREE.Object3D();
        var size: Float = 6;
        var geometry: THREE.PlaneGeometry = new THREE.PlaneGeometry(size, size);
        var settings: Array<Dynamic> = [
            { position: [-1, 0, 0], up: [0, 1, 0] },
            { position: [1, 0, 0], up: [0, -1, 0] },
            { position: [0, -1, 0], up: [0, 0, -1] },
            { position: [0, 1, 0], up: [0, 0, 1] },
            { position: [0, 0, -1], up: [1, 0, 0] },
            { position: [0, 0, 1], up: [-1, 0, 0] }
        ];
        for (i in 0...settings.length) {
            var material: THREE.MeshBasicMaterial = new THREE.MeshBasicMaterial({ side: side });
            material.color.setHSL(i / 6, 0.5, 0.5);
            var mesh: THREE.Mesh = new THREE.Mesh(geometry, material);
            mesh.up.set(settings[i].up[0], settings[i].up[1], settings[i].up[2]);
            mesh.lookAt(settings[i].position[0], settings[i].position[1], settings[i].position[2]);
            mesh.position.set(settings[i].position[0], settings[i].position[1], settings[i].position[2]).multiplyScalar(size * 0.75);
            base.add(mesh);
        }
        return base;
    }

    static function makeStandardPhysicalMaterialGrid(elem: Element, physical: Bool, update: Null<(Array<Array<THREE.Mesh>>) -> Void> = null): Dynamic {
        var numMetal: Int = 5;
        var numRough: Int = 7;
        var meshes: Array<Array<THREE.Mesh>> = [];
        var MatCtor: Class<THREE.Material> = physical ? THREE.MeshPhysicalMaterial : THREE.MeshStandardMaterial;
        var color: String = physical ? 'hsl(160,50%,50%)' : 'hsl(140,50%,50%)';
        for (m in 0...numMetal) {
            var row: Array<THREE.Mesh> = [];
            for (r in 0...numRough) {
                var material: THREE.Material = new MatCtor({
                    color: color,
                    roughness: r / (numRough - 1),
                    metalness: 1 - m / (numMetal - 1)
                });
                var mesh: THREE.Mesh = new THREE.Mesh(highPolySphereGeometry, material);
                row.push(mesh);
            }
            meshes.push(row);
        }

        return {
            obj3D: null,
            trackball: false,
            render(renderInfo: Dynamic) {
                var camera: THREE.Camera = renderInfo.camera;
                var scene: THREE.Scene = renderInfo.scene;
                var renderer: THREE.WebGLRenderer = renderInfo.renderer;
                var rect: ClientRect = elem.getBoundingClientRect();

                var width: Float = (rect.right - rect.left) * renderInfo.pixelRatio;
                var height: Float = (rect.bottom - rect.top) * renderInfo.pixelRatio;
                var left: Float = rect.left * renderInfo.pixelRatio;
                var bottom: Float = (renderer.domElement.clientHeight - rect.bottom) * renderInfo.pixelRatio;

                var cellSize: Int = Math.min(width / numRough, height / numMetal) | 0;
                var xOff: Float = (width - cellSize * numRough) / 2;
                var yOff: Float = (height - cellSize * numMetal) / 2;

                camera.aspect = 1;
                camera.updateProjectionMatrix();

                if (update != null) {
                    update(meshes);
                }

                for (m in 0...numMetal) {
                    for (r in 0...numRough) {
                        var x: Float = left + xOff + r * cellSize;
                        var y: Float = bottom + yOff + m * cellSize;
                        renderer.setViewport(x, y, cellSize, cellSize);
                        renderer.setScissor(x, y, cellSize, cellSize);
                        var mesh: THREE.Mesh = meshes[m][r];
                        scene.add(mesh);
                        renderer.render(scene, camera);
                        scene.remove(mesh);
                    }
                }
            }
        };
    }

    static function main() {
        threejsLessonUtils.addDiagrams({
            smoothShading: {
                create() {
                    return smoothOrFlat(false);
                }
            },
            flatShading: {
                create() {
                    return smoothOrFlat(true);
                }
            },
            MeshBasicMaterial: {
                create() {
                    return basicLambertPhongExample(THREE.MeshBasicMaterial);
                }
            },
            MeshLambertMaterial: {
                create() {
                    return basicLambertPhongExample(THREE.MeshLambertMaterial);
                }
            },
            MeshPhongMaterial: {
                create() {
                    return basicLambertPhongExample(THREE.MeshPhongMaterial);
                }
            },
            MeshBasicMaterialLowPoly: {
                create() {
                    return basicLambertPhongExample(THREE.MeshBasicMaterial, true);
                }
            },
            MeshLambertMaterialLowPoly: {
                create() {
                    return basicLambertPhongExample(THREE.MeshLambertMaterial, true);
                }
            },
            MeshPhongMaterialLowPoly: {
                create() {
                    return basicLambertPhongExample(THREE.MeshPhongMaterial, true);
                }
            },
            MeshPhongMaterialShininess0: {
                create() {
                    return basicLambertPhongExample(THREE.MeshPhongMaterial, false, {
                        color: 'red',
                        shininess: 0
                    });
                }
            },
            MeshPhongMaterialShininess30: {
                create() {
                    return basicLambertPhongExample(THREE.MeshPhongMaterial, false, {
                        color: 'red',
                        shininess: 30
                    });
                }
            },
            MeshPhongMaterialShininess150: {
                create() {
                    return basicLambertPhongExample(THREE.MeshPhongMaterial, false, {
                        color: 'red',
                        shininess: 150
                    });
                }
            },
            MeshBasicMaterialCompare: {
                create() {
                    return basicLambertPhongExample(THREE.MeshBasicMaterial, false, {
                        color: 'purple'
                    });
                }
            },
            MeshLambertMaterialCompare: {
                create() {
                    return basicLambertPhongExample(THREE.MeshLambertMaterial, false, {
                        color: 'black',
                        emissive: 'purple'
                    });
                }
            },
            MeshPhongMaterialCompare: {
                create() {
                    return basicLambertPhongExample(THREE.MeshPhongMaterial, false, {
                        color: 'black',
                        emissive: 'purple',
                        shininess: 0
                    });
                }
            },
            MeshToonMaterial: {
                create() {
                    return basicLambertPhongExample(THREE.MeshToonMaterial);
                }
            },
            MeshStandardMaterial: {
                create(props: Dynamic) {
                    return makeStandardPhysicalMaterialGrid(props.renderInfo.elem, false);
                }
            },
            MeshPhysicalMaterial: {
                create(props: Dynamic) {
                    var settings: Dynamic = {
                        clearcoat: 0.5,
                        clearcoatRoughness: 0
                    };

                    function addElem(parent: Element, type: String, style: Dynamic = null): Element {
                        var elem: Element = document.createElement(type);
                        if (style != null) {
                            for (key in Reflect.fields(style)) {
                                elem.style.setProperty(key, style[key]);
                            }
                        }
                        parent.appendChild(elem);
                        return elem;
                    }

                    function addRange(elem: Element, obj: Dynamic, prop: String, min: Float, max: Float) {
                        var outer: Element = addElem(elem, 'div', {
                            width: '100%',
                            textAlign: 'center',
                            'font-family': 'monospace'
                        });

                        var div: Element = addElem(outer, 'div', {
                            textAlign: 'left',
                            display: 'inline-block'
                        });

                        var label: Element = addElem(div, 'label', {
                            display: 'inline-block',
                            width: '12em'
                        });
                        label.textContent = prop;

                        var num: Element = addElem(div, 'div', {
                            display: 'inline-block',
                            width: '3em'
                        });

                        function updateNum() {
                            num.textContent = obj[prop].toFixed(2);
                        }

                        updateNum();

                        var input: Element = addElem(div, 'input');
                        input.setAttribute('type', 'range');
                        input.setAttribute('min', '0');
                        input.setAttribute('max', '100');
                        input.setAttribute('value', ((obj[prop] - min) / (max - min) * 100).toString());
                        input.addEventListener('input', function(_) {
                            obj[prop] = min + (max - min) * Std.parseFloat(input.getAttribute('value')) / 100;
                            updateNum();
                        });
                    }

                    var elem: Element = props.renderInfo.elem;
                    addRange(elem, settings, 'clearcoat', 0, 1);
                    addRange(elem, settings, 'clearcoatRoughness', 0, 1);
                    var area: Element = addElem(elem, 'div', {
                        width: '100%',
                        height: '400px'
                    });

                    return makeStandardPhysicalMaterialGrid(area, true, function(meshes: Array<Array<THREE.Mesh>>) {
                        meshes.forEach(function(row: Array<THREE.Mesh>) {
                            row.forEach(function(mesh: THREE.Mesh) {
                                mesh.material.clearcoat = settings.clearcoat;
                                mesh.material.clearcoatRoughness = settings.clearcoatRoughness;
                            });
                        });
                    });
                }
            },
            MeshDepthMaterial: {
                create(props: Dynamic) {
                    var camera: THREE.Camera = props.camera;
                    var radius: Float = 4;
                    var tube: Float = 1.5;
                    var radialSegments: Int = 8;
                    var tubularSegments: Int = 64;
                    var p: Int = 2;
                    var q: Int = 3;
                    var geometry: THREE.TorusKnotGeometry = new THREE.TorusKnotGeometry(radius, tube, tubularSegments, radialSegments, p, q);
                    var material: THREE.MeshDepthMaterial = new THREE.MeshDepthMaterial();
                    camera.near = 7;
                    camera.far = 20;
                    return new THREE.Mesh(geometry, material);
                }
            },
            MeshNormalMaterial: {
                create() {
                    var radius: Float = 4;
                    var tube: Float = 1.5;
                    var radialSegments: Int = 8;
                    var tubularSegments: Int = 64;
                    var p: Int = 2;
                    var q: Int = 3;
                    var geometry: THREE.TorusKnotGeometry = new THREE.TorusKnotGeometry(radius, tube, tubularSegments, radialSegments, p, q);
                    var material: THREE.MeshNormalMaterial = new THREE.MeshNormalMaterial();
                    return new THREE.Mesh(geometry, material);
                }
            },
            sideDefault: {
                create() {
                    return sideExample(THREE.FrontSide);
                }
            },
            sideDouble: {
                create() {
                    return sideExample(THREE.DoubleSide);
                }
            }
        });
    }
}