package three.js.manual.resources;

import three.js.*;

class ThreejsMaterials {
    static function makeSphere(widthDivisions:Int, heightDivisions:Int):SphereGeometry {
        var radius:Float = 7;
        return new SphereGeometry(radius, widthDivisions, heightDivisions);
    }

    static var highPolySphereGeometry:SphereGeometry = makeSphere(100, 50);
    static var lowPolySphereGeometry:SphereGeometry = makeSphere(12, 9);

    static function smoothOrFlat(flatShading:Bool, radius:Float = 7):Mesh {
        var widthDivisions:Int = 12;
        var heightDivisions:Int = 9;
        var geometry:SphereGeometry = new SphereGeometry(radius, widthDivisions, heightDivisions);
        var material:MeshPhongMaterial = new MeshPhongMaterial({
            flatShading: flatShading,
            color: 0x808080
        });
        return new Mesh(geometry, material);
    }

    static function basicLambertPhongExample(MaterialCtor:Class<Material>, lowPoly:Bool, ?params:Dynamic):{ obj3D:Mesh, trackball:Bool } {
        var geometry:Geometry = lowPoly ? lowPolySphereGeometry : highPolySphereGeometry;
        var material:Material = new MaterialCtor({
            color: 0x343434,
            ...params
        });
        return {
            obj3D: new Mesh(geometry, material),
            trackball: lowPoly
        };
    }

    static function sideExample(side:Int):Object3D {
        var base:Object3D = new Object3D();
        var size:Float = 6;
        var geometry:PlaneGeometry = new PlaneGeometry(size, size);
        [
            { position: [-1, 0, 0], up: [0, 1, 0] },
            { position: [1, 0, 0], up: [0, -1, 0] },
            { position: [0, -1, 0], up: [0, 0, -1] },
            { position: [0, 1, 0], up: [0, 0, 1] },
            { position: [0, 0, -1], up: [1, 0, 0] },
            { position: [0, 0, 1], up: [-1, 0, 0] },
        ].forEach((settings, ndx) -> {
            var material:MeshBasicMaterial = new MeshBasicMaterial({ side: side });
            material.color.setHSL(ndx / 6, 0.5, 0.5);
            var mesh:Mesh = new Mesh(geometry, material);
            mesh.up.set(settings.up.x, settings.up.y, settings.up.z);
            mesh.lookAt(settings.position[0], settings.position[1], settings.position[2]);
            mesh.position.set(settings.position[0], settings.position[1], settings.position[2]).multiplyScalar(size * 0.75);
            base.add(mesh);
        });
        return base;
    }

    static function makeStandardPhysicalMaterialGrid(elem:Dynamic, physical:Bool, update:Void->Void):{ obj3D:Object3D, trackball:Bool, render:RenderInfo->Void } {
        var numMetal:Int = 5;
        var numRough:Int = 7;
        var meshes:Array<Array<Mesh>> = [];
        var MatCtor:Class<Material> = physical ? MeshPhysicalMaterial : MeshStandardMaterial;
        var color:Int = physical ? 0xA0F0D0 : 0x8C9467;
        for (m in 0...numMetal) {
            var row:Array<Mesh> = [];
            for (r in 0...numRough) {
                var material:Material = new MatCtor({
                    color: color,
                    roughness: r / (numRough - 1),
                    metalness: 1 - m / (numMetal - 1)
                });
                var mesh:Mesh = new Mesh(highPolySphereGeometry, material);
                row.push(mesh);
            }
            meshes.push(row);
        }
        return {
            obj3D: null,
            trackball: false,
            render: function(renderInfo:RenderInfo) {
                var { camera, scene, renderer } = renderInfo;
                var rect:ClientRect = elem.getBoundingClientRect();
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
                        var mesh:Mesh = meshes[m][r];
                        scene.add(mesh);
                        renderer.render(scene, camera);
                        scene.remove(mesh);
                    }
                }
            }
        };
    }

    static function addDiagrams(diagrams:Dynamic) {
        diagrams.smoothShading = {
            create: function() {
                return smoothOrFlat(false);
            }
        };
        diagrams.flatShading = {
            create: function() {
                return smoothOrFlat(true);
            }
        };
        diagrams.MeshBasicMaterial = {
            create: function() {
                return basicLambertPhongExample(MeshBasicMaterial);
            }
        };
        diagrams.MeshLambertMaterial = {
            create: function() {
                return basicLambertPhongExample(MeshLambertMaterial);
            }
        };
        diagrams.MeshPhongMaterial = {
            create: function() {
                return basicLambertPhongExample(MeshPhongMaterial);
            }
        };
        diagrams.MeshBasicMaterialLowPoly = {
            create: function() {
                return basicLambertPhongExample(MeshBasicMaterial, true);
            }
        };
        diagrams.MeshLambertMaterialLowPoly = {
            create: function() {
                return basicLambertPhongExample(MeshLambertMaterial, true);
            }
        };
        diagrams.MeshPhongMaterialLowPoly = {
            create: function() {
                return basicLambertPhongExample(MeshPhongMaterial, true);
            }
        };
        diagrams.MeshPhongMaterialShininess0 = {
            create: function() {
                return basicLambertPhongExample(MeshPhongMaterial, false, { color: 0xFF0000, shininess: 0 });
            }
        };
        diagrams.MeshPhongMaterialShininess30 = {
            create: function() {
                return basicLambertPhongExample(MeshPhongMaterial, false, { color: 0xFF0000, shininess: 30 });
            }
        };
        diagrams.MeshPhongMaterialShininess150 = {
            create: function() {
                return basicLambertPhongExample(MeshPhongMaterial, false, { color: 0xFF0000, shininess: 150 });
            }
        };
        diagrams.MeshBasicMaterialCompare = {
            create: function() {
                return basicLambertPhongExample(MeshBasicMaterial, false, { color: 0x800080 });
            }
        };
        diagrams.MeshLambertMaterialCompare = {
            create: function() {
                return basicLambertPhongExample(MeshLambertMaterial, false, { color: 0x000000, emissive: 0x800080 });
            }
        };
        diagrams.MeshPhongMaterialCompare = {
            create: function() {
                return basicLambertPhongExample(MeshPhongMaterial, false, { color: 0x000000, emissive: 0x800080, shininess: 0 });
            }
        };
        diagrams.MeshToonMaterial = {
            create: function() {
                return basicLambertPhongExample(MeshToonMaterial);
            }
        };
        diagrams.MeshStandardMaterial = {
            create: function(props:Dynamic) {
                return makeStandardPhysicalMaterialGrid(props.renderInfo.elem, false);
            }
        };
        diagrams.MeshPhysicalMaterial = {
            create: function(props:Dynamic) {
                var settings:Dynamic = { clearcoat: 0.5, clearcoatRoughness: 0 };
                function addElem(parent:Dynamic, type:String, style:Dynamic = {}):Dynamic {
                    var elem:Dynamic = document.createElement(type);
                    Object.assign(elem.style, style);
                    parent.appendChild(elem);
                    return elem;
                }
                function addRange(elem:Dynamic, obj:Dynamic, prop:String, min:Float, max:Float):Void {
                    var outer:Dynamic = addElem(elem, 'div', { width: '100%', textAlign: 'center', fontFamily: 'monospace' });
                    var div:Dynamic = addElem(outer, 'div', { textAlign: 'left', display: 'inline-block' });
                    var label:Dynamic = addElem(div, 'label', { display: 'inline-block', width: '12em' });
                    label.textContent = prop;
                    var num:Dynamic = addElem(div, 'div', { display: 'inline-block', width: '3em' });
                    function updateNum():Void {
                        num.textContent = obj[prop].toFixed(2);
                    }
                    updateNum();
                    var input:Dynamic = addElem(div, 'input', {});
                    Object.assign(input, {
                        type: 'range',
                        min: 0,
                        max: 100,
                        value: (obj[prop] - min) / (max - min) * 100
                    });
                    input.addEventListener('input', function() {
                        obj[prop] = min + (max - min) * input.value / 100;
                        updateNum();
                    });
                }
                var { elem } = props.renderInfo;
                addRange(elem, settings, 'clearcoat', 0, 1);
                addRange(elem, settings, 'clearcoatRoughness', 0, 1);
                var area:Dynamic = addElem(elem, 'div', { width: '100%', height: '400px' });
                return makeStandardPhysicalMaterialGrid(area, true, function(meshes:Array<Array<Mesh>>) {
                    meshes.forEach(function(row:Array<Mesh>) {
                        row.forEach(function(mesh:Mesh) {
                            mesh.material.clearcoat = settings.clearcoat;
                            mesh.material.clearcoatRoughness = settings.clearcoatRoughness;
                        });
                    });
                });
            }
        };
        diagrams.MeshDepthMaterial = {
            create: function(props:Dynamic) {
                var { camera } = props;
                var radius:Float = 4;
                var tube:Float = 1.5;
                var radialSegments:Int = 8;
                var tubularSegments:Int = 64;
                var p:Int = 2;
                var q:Int = 3;
                var geometry:TorusKnotGeometry = new TorusKnotGeometry(radius, tube, tubularSegments, radialSegments, p, q);
                var material:MeshDepthMaterial = new MeshDepthMaterial();
                camera.near = 7;
                camera.far = 20;
                return new Mesh(geometry, material);
            }
        };
        diagrams.MeshNormalMaterial = {
            create: function() {
                var radius:Float = 4;
                var tube:Float = 1.5;
                var radialSegments:Int = 8;
                var tubularSegments:Int = 64;
                var p:Int = 2;
                var q:Int = 3;
                var geometry:TorusKnotGeometry = new TorusKnotGeometry(radius, tube, tubularSegments, radialSegments, p, q);
                var material:MeshNormalMaterial = new MeshNormalMaterial();
                return new Mesh(geometry, material);
            }
        };
        diagrams.sideDefault = {
            create: function() {
                return sideExample(THREE.FrontSide);
            }
        };
        diagrams.sideDouble = {
            create: function() {
                return sideExample(THREE.DoubleSide);
            }
        };
    }
}