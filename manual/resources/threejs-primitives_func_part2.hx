package threejs;

import js.html.Document;
import js.html.Element;
import js.three.BoxGeometry;
import js.three.EdgesGeometry;
import js.three.Geometry;
import js.three.LineBasicMaterial;
import js.three.Material;
import js.three.Mesh;
import js.three.MeshPhongMaterial;
import js.three.Object3D;
import js.three.PlaneGeometry;
import js.three.Points;
import js.three.PointsMaterial;
import js.three.SphereGeometry;
import js.three.TubeGeometry;
import js.three.Vector3;
import js.three.WireframeGeometry;

class CustomSinCurve extends Curve {
    public var scale:Float;

    public function new(scale:Float) {
        super();
        this.scale = scale;
    }

    override public function getPoint(t:Float) {
        var tx = t * 3 - 1.5;
        var ty = Math.sin(2 * Math.PI * t);
        var tz = 0;
        return new Vector3(tx, ty, tz).multiplyScalar(this.scale);
    }
}

class Diagrams {
    public static var diagrams:Map<String, {create:Void->Geometry, ui:Map<String, {type:String, min:Float, max:Float}>}>;

    public static function addLink(parent:Element, name:String, href:String) {
        var a = Document.createElement('a');
        a.target = '_blank';
        a.href = href != null ? href : 'https://threejs.org/docs/#api/geometries/$name';
        var code = Document.createElement('code');
        code.textContent = name;
        a.appendChild(code);
        parent.appendChild(a);
        return a;
    }

    public static function addDeepLink(parent:Element, name:String, href:String) {
        var a = Document.createElement('a');
        a.href = href != null ? href : 'https://threejs.org/docs/#api/geometries/$name';
        a.textContent = name;
        a.className = 'deep-link';
        parent.appendChild(a);
        return a;
    }

    public static function addElem(parent:Element, type:String, className:String, text:String) {
        var elem = Document.createElement(type);
        elem.className = className;
        if (text != null) {
            elem.textContent = text;
        }
        parent.appendChild(elem);
        return elem;
    }

    public static function addDiv(parent:Element, className:String) {
        return addElem(parent, 'div', className);
    }

    public static function createPrimitiveDOM(base:Element) {
        var name = base.dataset.primitive;
        var info = diagrams[name];
        if (info == null) {
            throw new Error('no primitive $name');
        }

        var text = base.innerHTML;
        base.innerHTML = '';

        var pair = addDiv(base, 'pair');
        var elem = addDiv(pair, 'shape');

        var right = addDiv(pair, 'desc');
        addDeepLink(right, '#', '#' + base.id);
        addLink(right, name);
        addDiv(right, '.note').innerHTML = text;

        function makeExample(elem:Element, createFn:Void->Geometry, src:String) {
            var rawLines = createFn.toString().replace(/return (new THREE\.[a-zA-Z]+Geometry)/, 'const geometry = $1').split('\n');
            var createRE = /^\s*(?:function *)*create\d*\((.*?)\)/;
            var indentRE = /^(\s*)[^\s]/;
            var m = indentRE.exec(rawLines[2]);
            var prefixLen = m[1].length;
            var m2 = createRE.exec(rawLines[0]);
            var argString = m2[1].trim();
            var trimmedLines = src != null ? src.split('\n').slice(1, -1) : rawLines.slice(1, rawLines.length - 1).map(function(line) return line.substring(prefixLen));
            if (info.addConstCode != false && argString != null) {
                var lines = argString.split(',').map(function(arg) return 'const ${arg.trim()};  // ui: ${arg.trim().split(' ')[0]}');
                var lineNdx = trimmedLines.findIndex(function(l) return l.indexOf('const geometry') >= 0);
                trimmedLines.splice(lineNdx < 0 ? 0 : lineNdx, 0, lines);
            }

            addElem(base, 'pre', 'prettyprint showmods', trimmedLines.join('\n'));

            createLiveImage(elem, { ...info, create: createFn }, name);
        }

        makeExample(elem, info.create, info.src);

        {
            var i = 2;
            while (true) {
                var createFn = info['create' + i];
                if (createFn == null) {
                    break;
                }

                var shapeElem = addDiv(base, 'shape');
                makeExample(shapeElem, createFn, info['src' + i]);
                i++;
            }
        }
    }

    public static function createDiagram(base:Element) {
        var name = base.dataset.diagram;
        var info = diagrams[name];
        if (info == null) {
            throw new Error('no diagram $name');
        }

        createLiveImage(base, info, name);
    }

    public static function addGeometry(root:Object3D, info:{create:Void->Geometry, material:Material}, args:Array<Float>) {
        var result = info.create.apply(null, args);
        var promise = result instanceof Promise ? result : Promise.resolve(result);

        promise.then(function(diagramInfo) {
            if (diagramInfo instanceof Geometry) {
                var geometry = diagramInfo;
                diagramInfo = {
                    geometry: geometry
                };
            }

            var geometry = diagramInfo.geometry || diagramInfo.lineGeometry || diagramInfo.mesh.geometry;
            geometry.computeBoundingBox();
            var centerOffset = new Vector3();
            geometry.boundingBox.getCenter(centerOffset).multiplyScalar(-1);

            var mesh = diagramInfo.mesh;
            if (diagramInfo.geometry != null) {
                if (info.material == null) {
                    var material = new MeshPhongMaterial({
                        flatShading: info.flatShading == false ? false : true,
                        side: THREE.DoubleSide
                    });
                    material.color.setHSL(Math.random(), .5, .5);
                    info.material = material;
                }

                mesh = new Mesh(diagramInfo.geometry, info.material);
            }

            if (mesh != null) {
                mesh.position.copy(centerOffset);
                root.add(mesh);
            }

            if (info.showLines != false) {
                var lineMesh = new LineSegments(diagramInfo.lineGeometry || diagramInfo.geometry, new LineBasicMaterial({
                    color: diagramInfo.geometry != null ? 0xffffff : 0xffffff,
                    transparent: true,
                    opacity: 0.5
                }));
                lineMesh.position.copy(centerOffset);
                root.add(lineMesh);
            }
        });
    }

    public static function updateGeometry(root:Object3D, info:{create:Void->Geometry, material:Material}, params:Map<String, Float>) {
        var oldChildren = root.children.slice();
        addGeometry(root, info, Object.values(params));
        oldChildren.forEach(function(child) {
            root.remove(child);
            child.geometry.dispose();
        });
    }

    public static function createLiveImage(elem:Element, info:{create:Void->Geometry, material:Material}, name:String) {
        var root = new Object3D();

        addGeometry(root, info);
        threejsLessonUtils.addDiagram(elem, { create: function() return root });
    }

    public static function main() {
        var primitives = {};

        async function createLiveImage(elem:Element, info:{create:Void->Geometry, material:Material}, name:String) {
            await addGeometry(new Object3D(), info);
            threejsLessonUtils.addDiagram(elem, { create: function() return new Object3D() });
        }

        var diagrams = {
            EdgesGeometry: {
                ui: {
                    thresholdAngle: { type: 'range', min: 1, max: 180 }
                },
                create: function() {
                    return {
                        lineGeometry: new EdgesGeometry(new BoxGeometry(8, 8, 8))
                    };
                },
                create2: function(thresholdAngle = 1) {
                    return {
                        lineGeometry: new EdgesGeometry(new SphereGeometry(7, 6, 3), thresholdAngle)
                    };
                },
                addConstCode: false,
                src: '
const size = 8;
const widthSegments = 2;
const heightSegments = 2;
const depthSegments = 2;
const boxGeometry = new BoxGeometry(
    size, size, size,
    widthSegments, heightSegments, depthSegments);
const geometry = new EdgesGeometry(boxGeometry);
',
                src2: '
const radius = 7;
const widthSegments = 6;
const heightSegments = 3;
const sphereGeometry = new SphereGeometry(
    radius, widthSegments, heightSegments);
const thresholdAngle = 1;  // ui: thresholdAngle
const geometry = new EdgesGeometry(sphereGeometry, thresholdAngle);
'
            },
            WireframeGeometry: {
                ui: {
                    widthSegments: { type: 'range', min: 1, max: 10 },
                    heightSegments: { type: 'range', min: 1, max: 10 },
                    depthSegments: { type: 'range', min: 1, max: 10 }
                },
                create: function(widthSegments = 2, heightSegments = 2, depthSegments = 2) {
                    const size = 8;
                    return {
                        lineGeometry: new WireframeGeometry(new BoxGeometry(size, size, size, widthSegments, heightSegments, depthSegments))
                    };
                },
                addConstCode: false,
                src: '
const size = 8;
const widthSegments = 2;  // ui: widthSegments
const heightSegments = 2;  // ui: heightSegments
const depthSegments = 2;  // ui: depthSegments
const geometry = new WireframeGeometry(
    new BoxGeometry(
      size, size, size,
      widthSegments, heightSegments, depthSegments));
'
            },
            Points: {
                create: function() {
                    const radius = 7;
                    const widthSegments = 12;
                    const heightSegments = 8;
                    const geometry = new SphereGeometry(radius, widthSegments, heightSegments);
                    const material = new PointsMaterial({
                        color: 'red',
                        size: 0.2
                    });
                    const points = new Points(geometry, material);
                    return {
                        showLines: false,
                        mesh: points
                    };
                }
            },
            PointsUniformSize: {
                create: function() {
                    const radius = 7;
                    const widthSegments = 12;
                    const heightSegments = 8;
                    const geometry = new SphereGeometry(radius, widthSegments, heightSegments);
                    const material = new PointsMaterial({
                        color: 'red',
                        size: 3 * window.devicePixelRatio,
                        sizeAttenuation: false
                    });
                    const points = new Points(geometry, material);
                    return {
                        showLines: false,
                        mesh: points
                    };
                }
            },
            SphereGeometryLow: {
                create: function(radius = 7, widthSegments = 5, heightSegments = 3) {
                    return new SphereGeometry(radius, widthSegments, heightSegments);
                }
            },
            SphereGeometryMedium: {
                create: function(radius = 7, widthSegments = 24, heightSegments = 10) {
                    return new SphereGeometry(radius, widthSegments, heightSegments);
                }
            },
            SphereGeometryHigh: {
                create: function(radius = 7, widthSegments = 50, heightSegments = 50) {
                    return new SphereGeometry(radius, widthSegments, heightSegments);
                }
            },
            SphereGeometryLowSmooth: {
                create: function(radius = 7, widthSegments = 5, heightSegments = 3) {
                    return new SphereGeometry(radius, widthSegments, heightSegments);
                },
                showLines: false,
                flatShading: false
            },
            SphereGeometryMediumSmooth: {
                create: function(radius = 7, widthSegments = 24, heightSegments = 10) {
                    return new SphereGeometry(radius, widthSegments, heightSegments);
                },
                showLines: false,
                flatShading: false
            },
            SphereGeometryHighSmooth: {
                create: function(radius = 7, widthSegments = 50, heightSegments = 50) {
                    return new SphereGeometry(radius, widthSegments, heightSegments);
                },
                showLines: false,
                flatShading: false
            },
            PlaneGeometryLow: {
                create: function(width = 9, height = 9, widthSegments = 1, heightSegments = 1) {
                    return new PlaneGeometry(width, height, widthSegments, heightSegments);
                }
            },
            PlaneGeometryHigh: {
                create: function(width = 9, height = 9, widthSegments = 10, heightSegments = 10) {
                    return new PlaneGeometry(width, height, widthSegments, heightSegments);
                }
            }
        };

        document.querySelectorAll('[data-primitive]').forEach(function(base) {
            createPrimitiveDOM(base);
        });

        document.querySelectorAll('[data-diagram]').forEach(function(base) {
            createDiagram(base);
        });
    }

    public static function main() {
        main();
    }
}