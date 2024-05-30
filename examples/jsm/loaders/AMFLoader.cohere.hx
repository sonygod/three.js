package;

import js.Browser;
import js.three.*;
import js.fflate.*;

class AMFLoader extends Loader {
    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Function, onProgress:Function, onError:Function):Void {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.path = scope.path;
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(text) {
            try {
                onLoad(scope.parse(text));
            } catch (e) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    private function parse(data:ArrayBuffer):Group {
        function loadDocument(data:ArrayBuffer):XML {
            var view = new DataView(data);
            var magic = String.fromCharCode(view.getUint8(0), view.getUint8(1));

            if (magic == 'PK') {
                var zip:Dynamic = null;
                var file:String = null;

                trace('THREE.AMFLoader: Loading Zip');

                try {
                    zip = fflate.unzipSync(new Uint8Array(data));
                } catch (e) {
                    if (e instanceof ReferenceError) {
                        trace('THREE.AMFLoader: fflate missing and file is compressed.');
                        return null;
                    }
                }

                for (file in zip) {
                    if (file.toLowerCase().endsWith('.amf')) {
                        break;
                    }
                }

                trace('THREE.AMFLoader: Trying to load file asset: ' + file);
                view = new DataView(zip[file].buffer);
            }

            var fileText = new TextDecoder().decode(view);
            var xmlData = new DOMParser().parseFromString(fileText, 'application/xml');

            if (xmlData.documentElement.nodeName.toLowerCase() != 'amf') {
                trace('THREE.AMFLoader: Error loading AMF - no AMF document found.');
                return null;
            }

            return xmlData;
        }

        function loadDocumentScale(node:XML):Float {
            var scale:Float = 1.0;
            var unit:String = 'millimeter';

            if (node.documentElement.attributes.unit != null) {
                unit = node.documentElement.attributes.unit.value.toLowerCase();
            }

            var scaleUnits = {
                'millimeter': 1.0,
                'inch': 25.4,
                'feet': 304.8,
                'meter': 1000.0,
                'micron': 0.001
            };

            if (scaleUnits.exists(unit)) {
                scale = scaleUnits[unit];
            }

            trace('THREE.AMFLoader: Unit scale: ' + scale);
            return scale;
        }

        function loadMaterials(node:XML):Dynamic {
            var matName:String = 'AMF Material';
            var matId:String = node.attributes.id.textContent;
            var color:Dynamic = { r: 1.0, g: 1.0, b: 1.0, a: 1.0 };

            var loadedMaterial:MeshPhongMaterial = null;

            for (i in 0...node.childNodes.length) {
                var matChildEl = node.childNodes[i];

                if (matChildEl.nodeName == 'metadata' && matChildEl.attributes.type != null) {
                    if (matChildEl.attributes.type.value == 'name') {
                        matName = matChildEl.textContent;
                    }
                } else if (matChildEl.nodeName == 'color') {
                    color = loadColor(matChildEl);
                }
            }

            loadedMaterial = new MeshPhongMaterial({
                flatShading: true,
                color: new Color(color.r, color.g, color.b),
                name: matName
            });

            if (color.a != 1.0) {
                loadedMaterial.transparent = true;
                loadedMaterial.opacity = color.a;
            }

            return { id: matId, material: loadedMaterial };
        }

        function loadColor(node:XML):Dynamic {
            var color:Dynamic = { r: 1.0, g: 1.0, b: 1.0, a: 1.0 };

            for (i in 0...node.childNodes.length) {
                var matColor = node.childNodes[i];

                if (matColor.nodeName == 'r') {
                    color.r = Std.parseFloat(matColor.textContent);
                } else if (matColor.nodeName == 'g') {
                    color.g = Std.parseFloat(matColor.textContent);
                } else if (matColor.nodeName == 'b') {
                    color.b = Std.parseFloat(matColor.textContent);
                } else if (matColor.nodeName == 'a') {
                    color.a = Std.parseFloat(matColor.textContent);
                }
            }

            return color;
        }

        function loadMeshVolume(node:XML):Dynamic {
            var volume:Dynamic = { name: '', triangles: [], materialid: null };
            var currVolumeNode = node.firstElementChild;

            if (node.attributes.materialid != null) {
                volume.materialId = node.attributes.materialid.nodeValue;
            }

            while (currVolumeNode != null) {
                if (currVolumeNode.nodeName == 'metadata') {
                    if (currVolumeNode.attributes.type != null) {
                        if (currVolumeNode.attributes.type.value == 'name') {
                            volume.name = currVolumeNode.textContent;
                        }
                    }
                } else if (currVolumeNode.nodeName == 'triangle') {
                    var v1 = currVolumeNode.getElementsByTagName('v1')[0].textContent;
                    var v2 = currVolumeNode.getElementsByTagName('v2')[0].textContent;
                    var v3 = currVolumeNode.getElementsByTagName('v3')[0].textContent;

                    volume.triangles.push(v1, v2, v3);
                }

                currVolumeNode = currVolumeNode.nextElementSibling;
            }

            return volume;
        }

        function loadMeshVertices(node:XML):Dynamic {
            var vertArray:Array<Float> = [];
            var normalArray:Array<Float> = [];
            var currVerticesNode = node.firstElementChild;

            while (currVerticesNode != null) {
                if (currVerticesNode.nodeName == 'vertex') {
                    var vNode = currVerticesNode.firstElementChild;

                    while (vNode != null) {
                        if (vNode.nodeName == 'coordinates') {
                            var x = vNode.getElementsByTagName('x')[0].textContent;
                            var y = vNode.getElementsByTagName('y')[0].textContent;
                            var z = vNode.getElementsByTagName('z')[0].textContent;

                            vertArray.push(Std.parseFloat(x), Std.parseFloat(y), Std.parseFloat(z));
                        } else if (vNode.nodeName == 'normal') {
                            var nx = vNode.getElementsByTagName('nx')[0].textContent;
                            var ny = vNode.getElementsByTagName('ny')[0].textContent;
                            var nz = vNode.getElementsByTagName('nz')[0].textContent;

                            normalArray.push(Std.parseFloat(nx), Std.parseFloat(ny), Std.parseFloat(nz));
                        }

                        vNode = vNode.nextElementSibling;
                    }
                }

                currVerticesNode = currVerticesNode.nextElementSibling;
            }

            return { 'vertices': vertArray, 'normals': normalArray };
        }

        function loadObject(node:XML):Dynamic {
            var objId:String = node.attributes.id.textContent;
            var loadedObject:Dynamic = { name: 'amfobject', meshes: [] };
            var currColor:Dynamic = null;
            var currObjNode = node.firstElementChild;

            while (currObjNode != null) {
                if (currObjNode.nodeName == 'metadata') {
                    if (currObjNode.attributes.type != null) {
                        if (currObjNode.attributes.type.value == 'name') {
                            loadedObject.name = currObjNode.textContent;
                        }
                    }
                } else if (currObjNode.nodeName == 'color') {
                    currColor = loadColor(currObjNode);
                } else if (currObjNode.nodeName == 'mesh') {
                    var currMeshNode = currObjNode.firstElementChild;
                    var mesh:Dynamic = { vertices: [], normals: [], volumes: [], color: currColor };

                    while (currMeshNode != null) {
                        if (currMeshNode.nodeName == 'vertices') {
                            var loadedVertices = loadMeshVertices(currMeshNode);
                            mesh.normals = mesh.normals.concat(loadedVertices.normals);
                            mesh.vertices = mesh.vertices.concat(loadedVertices.vertices);
                        } else if (currMeshNode.nodeName == 'volume') {
                            mesh.volumes.push(loadMeshVolume(currMeshNode));
                        }

                        currMeshNode = currMeshNode.nextElementSibling;
                    }

                    loadedObject.meshes.push(mesh);
                }

                currObjNode = currObjNode.nextElementSibling;
            }

            return { 'id': objId, 'obj': loadedObject };
        }

        var xmlData = loadDocument(data);
        var amfName:String = '';
        var amfAuthor:String = '';
        var amfScale = loadDocumentScale(xmlData);
        var amfMaterials:Dynamic = {};
        var amfObjects:Dynamic = {};
        var childNodes = xmlData.documentElement.childNodes;

        for (i in 0...childNodes.length) {
            var child = childNodes[i];

            if (child.nodeName == 'metadata') {
                if (child.attributes.type != null) {
                    if (child.attributes.type.value == 'name') {
                        amfName = child.textContent;
                    } else if (child.attributes.type.value == 'author') {
                        amfAuthor = child.textContent;
                    }
                }
            } else if (child.nodeName == 'material') {
                var loadedMaterial = loadMaterials(child);
                amfMaterials[loadedMaterial.id] = loadedMaterial.material;
            } else if (child.nodeName == 'object') {
                var loadedObject = loadObject(child);
                amfObjects[loadedObject.id] = loadedObject.obj;
            }
        }

        var sceneObject = new Group();
        var defaultMaterial = new MeshPhongMaterial({
            name: Loader.DEFAULT_MATERIAL_NAME,
            color: 0xaaaaff,
            flatShading: true
        });

        sceneObject.name = amfName;
        sceneObject.userData.author = amfAuthor;
        sceneObject.userData.loader = 'AMF';

        for (id in amfObjects) {
            var part = amfObjects[id];
            var meshes = part.meshes;
            var newObject = new Group();
            newObject.name = part.name;

            for (i in 0...meshes.length) {
                var objDefaultMaterial = defaultMaterial;
                var mesh = meshes[i];
                var vertices = new Float32BufferAttribute(mesh.vertices, 3);
                var normals:Float32BufferAttribute = null;

                if (mesh.normals.length > 0) {
                    normals = new Float32BufferAttribute(mesh.normals, 3);
                }

                if (mesh.color != null) {
                    var color = mesh.color;
                    objDefaultMaterial = defaultMaterial.clone();
                    objDefaultMaterial.color = new Color(color.r, color.g, color.b);

                    if (color.a != 1.0) {
                        objDefaultMaterial.transparent = true;
                        objDefaultMaterial.opacity = color.a;
                    }
                }

                var volumes = mesh.volumes;

                for (j in 0...volumes.length) {
                    var volume = volumes[j];
                    var newGeometry = new BufferGeometry();
                    var material:MeshPhongMaterial = objDefaultMaterial;

                    newGeometry.setIndex(volume.triangles);
                    newGeometry.setAttribute('position', vertices.clone());

                    if (normals != null) {
                        newGeometry.setAttribute('normal', normals.clone());
                    }

                    if (amfMaterials.exists(volume.materialId)) {
                        material = amfMaterials[volume.materialId];
                    }

                    newGeometry.scale(amfScale, amfScale, amfScale);
                    newObject.add(new Mesh(newGeometry, material.clone()));
                }
            }

            sceneObject.add(newObject);
        }

        return sceneObject;
    }
}

class Dynamic {
    public function exists(key:String):Bool {
        return this.hasOwnProperty(key);
    }
}