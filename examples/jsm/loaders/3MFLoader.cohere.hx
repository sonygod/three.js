import haxe.io.Bytes;
import js.Browser.window;
import js.html.Blob;
import js.html.URL;
import js.html.ImageData;
import js.html.CanvasElement;
import js.html.Image;
import js.html.Option;
import js.html.OptionElement;
import js.html.Storage;
import js.node.Fs;

import js.three.BufferAttribute;
import js.three.BufferGeometry;
import js.three.ClampToEdgeWrapping;
import js.three.Color;
import js.three.FileLoader;
import js.three.Float32BufferAttribute;
import js.three.Group;
import js.three.LinearFilter;
import js.three.LinearMipmapLinearFilter;
import js.three.Loader;
import js.three.Matrix4;
import js.three.Mesh;
import js.three.MeshPhongMaterial;
import js.three.MeshStandardMaterial;
import js.three.MirroredRepeatWrapping;
import js.three.NearestFilter;
import js.three.RepeatWrapping;
import js.three.SRGBColorSpace;
import js.three.TextureLoader;

class ThreeMFLoader extends Loader {
    public function new(manager:Dynamic) {
        super(manager);
        this.availableExtensions = [];
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.path = scope.path;
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(buffer) {
            try {
                onLoad(scope.parse(buffer));
            } catch (e) {
                if (onError) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(data:Bytes):Group {
        var scope = this;
        var textureLoader = new TextureLoader(this.manager);

        function loadDocument(data:Bytes):Dynamic {
            var zip = null;
            var file = null;

            var relsName:String;
            var modelRelsName:String;
            var modelPartNames = [];
            var texturesPartNames = [];

            var modelRels:Dynamic;
            var modelParts = {};
            var printTicketParts = {};
            var texturesParts = {};

            var textDecoder = new TextDecoder();

            try {
                zip = fflate.unzipSync(data.getData());
            } catch (e) {
                if (e instanceof ReferenceError) {
                    trace('THREE.3MFLoader: fflate missing and file is compressed.');
                    return null;
                }
            }

            for (file in zip) {
                if (file.match(/_rels\/.*\.rels$/)) {
                    relsName = file;
                } else if (file.match(/3D\/.*\.model\.rels$/)) {
                    modelRelsName = file;
                } else if (file.match(/^3D\/.*\.model$/)) {
                    modelPartNames.push(file);
                } else if (file.match(/^3D\/Textures?\/.*/)) {
                    texturesPartNames.push(file);
                }
            }

            if (relsName == null) throw new Error('THREE.ThreeMFLoader: Cannot find relationship file `rels` in 3MF archive.');

            var relsView = zip[relsName];
            var relsFileText = textDecoder.decode(relsView);
            var rels = parseRelsXml(relsFileText);

            if (modelRelsName != null) {
                var relsView = zip[modelRelsName];
                var relsFileText = textDecoder.decode(relsView);
                modelRels = parseRelsXml(relsFileText);
            }

            for (_i = 0; _i < modelPartNames.length; _i++) {
                var modelPart = modelPartNames[_i];
                var view = zip[modelPart];

                var fileText = textDecoder.decode(view);
                var xmlData = new DOMParser().parseFromString(fileText, 'application/xml');

                if (xmlData.documentElement.nodeName.toLowerCase() != 'model') {
                    trace('THREE.3MFLoader: Error loading 3MF - no 3MF document found: ', modelPart);
                }

                var modelNode = xmlData.querySelector('model');
                var extensions = {};

                for (_j = 0; _j < modelNode.attributes.length; _j++) {
                    var attr = modelNode.attributes[_j];
                    if (attr.name.match(/^xmlns:(.+)$/)) {
                        extensions[attr.value] = RegExp.$1;
                    }
                }

                var modelData = parseModelNode(modelNode);
                modelData['xml'] = modelNode;

                if (0 < Object.keys(extensions).length) {
                    modelData['extensions'] = extensions;
                }

                modelParts[modelPart] = modelData;
            }

            for (_k = 0; _k < texturesPartNames.length; _k++) {
                var texturesPartName = texturesPartNames[_k];
                texturesParts[texturesPartName] = zip[texturesPartName].buffer;
            }

            return {
                rels: rels,
                modelRels: modelRels,
                model: modelParts,
                printTicket: printTicketParts,
                texture: texturesParts
            };
        }

        function parseRelsXml(relsFileText:String):Array<Dynamic> {
            var relationships = [];

            var relsXmlData = new DOMParser().parseFromString(relsFileText, 'application/xml');

            var relsNodes = relsXmlData.querySelectorAll('Relationship');

            for (_l = 0; _l < relsNodes.length; _l++) {
                var relsNode = relsNodes[_l];

                var relationship = {
                    target: relsNode.getAttribute('Target'), //required
                    id: relsNode.getAttribute('Id'), //required
                    type: relsNode.getAttribute('Type') //required
                };

                relationships.push(relationship);
            }

            return relationships;
        }

        function parseMetadataNodes(metadataNodes:Dynamic):Dynamic {
            var metadataData = {};

            for (_m = 0; _m < metadataNodes.length; _m++) {
                var metadataNode = metadataNodes[_m];
                var name = metadataNode.getAttribute('name');
                var validNames = [
                    'Title',
                    'Designer',
                    'Description',
                    'Copyright',
                    'LicenseTerms',
                    'Rating',
                    'CreationDate',
                    'ModificationDate'
                ];

                if (0 <= validNames.indexOf(name)) {
                    metadataData[name] = metadataNode.textContent;
                }
            }

            return metadataData;
        }

        function parseBasematerialsNode(basematerialsNode:Dynamic):Dynamic {
            var basematerialsData = {
                id: basematerialsNode.getAttribute('id'), // required
                basematerials: []
            };

            var basematerialNodes = basematerialsNode.querySelectorAll('base');

            for (_n = 0; _n < basematerialNodes.length; _n++) {
                var basematerialNode = basematerialNodes[_n];
                var basematerialData = parseBasematerialNode(basematerialNode);
                basematerialData.index = _n; // the order and count of the material nodes form an implicit 0-based index
                basematerialsData.basematerials.push(basematerialData);
            }

            return basematerialsData;
        }

        function parseTexture2DNode(texture2DNode:Dynamic):Dynamic {
            var texture2dData = {
                id: texture2DNode.getAttribute('id'), // required
                path: texture2DNode.getAttribute('path'), // required
                contenttype: texture2DNode.getAttribute('contenttype'), // required
                tilestyleu: texture2DNode.getAttribute('tilestyleu'),
                tilestylev: texture2DNode.getAttribute('tilestylev'),
                filter: texture2DNode.getAttribute('filter'),
            };

            return texture2dData;
        }

        function parseTextures2DGroupNode(texture2DGroupNode:Dynamic):Dynamic {
            var texture2DGroupData = {
                id: texture2DGroupNode.getAttribute('id'), // required
                texid: texture2DGroupNode.getAttribute('texid'), // required
                displaypropertiesid: texture2DGroupNode.getAttribute('displaypropertiesid')
            };

            var tex2coordNodes = texture2DGroupNode.querySelectorAll('tex2coord');

            var uvs = [];

            for (_o = 0; _o < tex2coordNodes.length; _o++) {
                var tex2coordNode = tex2coordNodes[_o];
                var u = Std.parseFloat(tex2coordNode.getAttribute('u'));
                var v = Std.parseFloat(tex2coordNode.getAttribute('v'));

                uvs.push(u, v);
            }

            texture2DGroupData['uvs'] = new Float32Array(uvs);

            return texture2DGroupData;
        }

        function parseColorGroupNode(colorGroupNode:Dynamic):Dynamic {
            var colorGroupData = {
                id: colorGroupNode.getAttribute('id'), // required
                displaypropertiesid: colorGroupNode.getAttribute('displaypropertiesid')
            };

            var colorNodes = colorGroupNode.querySelectorAll('color');

            var colors = [];
            var colorObject = new Color();

            for (_p = 0; _p < colorNodes.length; _p++) {
                var colorNode = colorNodes[_p];
                var color = colorNode.getAttribute('color');

                colorObject.setStyle(color.substring(0, 7), COLOR_SPACE_3MF);

                colors.push(colorObject.r, colorObject.g, colorObject.b);
            }

            colorGroupData['colors'] = new Float32Array(colors);

            return colorGroupData;
        }

        function parseMetallicDisplaypropertiesNode(metallicDisplaypropetiesNode:Dynamic):Dynamic {
            var metallicDisplaypropertiesData = {
                id: metallicDisplaypropetiesNode.getAttribute('id') // required
            };

            var metallicNodes = metallicDisplaypropetiesNode.querySelectorAll('pbmetallic');

            var metallicData = [];

            for (_q = 0; _q < metallicNodes.length; _q++) {
                var metallicNode = metallicNodes[_q];

                metallicData.push({
                    name: metallicNode.getAttribute('name'), // required
                    metallicness: Std.parseFloat(metallicNode.getAttribute('metallicness')), // required
                    roughness: Std.parseFloat(metallicNode.getAttribute('roughness')) // required
                });
            }

            metallicDisplaypropertiesData.data = metallicData;

            return metallicDisplaypropertiesData;
        }

        function parseBasematerialNode(basematerialNode:Dynamic):Dynamic {
            var basematerialData = {};

            basematerialData['name'] = basematerialNode.getAttribute('name'); // required
            basematerialData['displaycolor'] = basematerialNode.getAttribute('displaycolor'); // required
            basematerialData['displaypropertiesid'] = basematerialNode.getAttribute('displaypropertiesid');

            return basematerialData;
        }

        function parseMeshNode(meshNode:Dynamic):Dynamic {
            var meshData = {};

            var vertices = [];
            var vertexNodes = meshNode.querySelectorAll('vertices vertex');

            for (_r = 0; _r < vertexNodes.length; _r++) {
                var vertexNode = vertexNodes[_r];
                var x = Std.parseFloat(vertexNode.getAttribute('x'));
                var y = Std.parseFloat(vertexNode.getAttribute('y'));
                var z = Std.parseFloat(vertexNode.getAttribute('z'));

                vertices.push(x, y, z);
            }

            meshData['vertices'] = new Float32Array(vertices);

            var triangleProperties = [];
            var triangles = [];
            var triangleNodes = meshNode.querySelectorAll('triangles triangle');

            for (_s = 0; _s < triangleNodes.length; _s++) {
                var triangleNode = triangleNodes[_s];
                var v1 = Std.parseInt(triangleNode.getAttribute('v1'));
                var v2 = Std.parseInt(triangleNode.getAttribute('v2'));
                var v3 = Std.parseInt(triangleNode.getAttribute('v3'));
                var p1 = triangleNode.getAttribute('p1');
                var p2 = triangleNode.getAttribute('p2');
                var p3 = triangleNode.getAttribute('p3');
                var pid = triangleNode.getAttribute('pid');

                var triangleProperty = {};

                triangleProperty['v1'] = v1;
                triangleProperty['v2'] = v2;
                triangleProperty['v3'] = v3;

                triangles.push(triangleProperty['v1'], triangleProperty['v2'], triangleProperty['v3']);

                // optional

                if (p1 != null) {
                    triangleProperty['p1'] = Std.parseInt(p1);
                }

                if (p2 != null) {
                    triangleProperty['p2'] = Std.parseInt(p2);
                }

                if (p3 != null) {
                    triangleProperty['p3'] = Std.parseInt(p3);
                }

                if (pid != null) {
                    triangleProperty['pid'] = pid;
                }

                if (0 < Object.keys(triangleProperty).length) {
                    triangleProperties.push(triangleProperty);
                }
            }

            meshData['triangleProperties'] = triangleProperties;
            meshData['triangles'] = new Uint32Array(triangles);

            return meshData;
        }

        function parseComponentsNode(componentsNode:Dynamic):Array<Dynamic> {
            var components = [];

            var componentNodes = componentsNode.querySelectorAll('component');

            for (_t = 0; _t < componentNodes.length; _t++) {
                var componentNode = componentNodes[_t];
                var componentData = parseComponentNode(componentNode);
                components.push(componentData);
            }

            return components;
        }

        function parseComponentNode(componentNode:Dynamic):Dynamic {
            var componentData = {};

            componentData['objectId'] = componentNode.getAttribute('objectid'); // required

            var transform = componentNode.getAttribute('transform');

            if (transform != null) {
                componentData['transform'] = parseTransform(transform);
            }

            return componentData;
        }

        function parseTransform(transform:String):Matrix4 {
            var t = [];
            transform.split(' ').forEach(function(s) {
                t.push(Std.parseFloat(s));
            });

            var matrix = new Matrix4();
            matrix.set(
                t[0], t[3], t[6], t[9],
                t[1], t[4], t[7], t[10],
                t[2], t[5], t[8], t[11],
                0.0, 0.0, 0.0, 1.0
            );

            return matrix;
        }

        function parseObjectNode(objectNode:Dynamic):Dynamic {
            var objectData = {
                type: objectNode.getAttribute('type')
            };

            var id = objectNode.getAttribute('id');

            if (id != null) {
                objectData['id'] = id;
            }

            var pid = objectNode.getAttribute('pid');

            if (pid != null) {
                objectData['pid'] = pid;
            }

            var pindex = objectNode.getAttribute('pindex');

            if (pindex != null) {
                objectData['pindex'] = pindex;
            }

            var thumbnail = objectNode.getAttribute('thumbnail');

            if (thumbnail != null) {
                objectData['thumbnail'] = thumbnail;
            }

            var partnumber = objectNode.getAttribute('partnumber');

            if (partnumber != null) {
                objectData['partnumber'] = partnumber;
            }

            var name = objectNode.getAttribute('name');

            if (name != null) {
                objectData['name'] = name;
            }

            var meshNode = objectNode.querySelector('mesh');

            if (meshNode != null) {
                objectData['mesh'] = parseMeshNode(meshNode);
            }

            var componentsNode = objectNode.querySelector('components');

            if (componentsNode != null) {
                objectData['components'] = parseComponentsNode(componentsNode);
            }

            return objectData;
        }

        function parseResourcesNode(resourcesNode:Dynamic):Dynamic {
            var resourcesData = {};

            resourcesData['basematerials'] = {};
            var basematerialsNodes = resourcesNode.querySelectorAll('basematerials');

            for (_u = 0; _u < basematerialsNodes.length; _u++) {
                var basematerialsNode = basematerialsNodes[_u];
                var basematerialsData = parseBasematerialsNode(basematerialsNode);
                resourcesData['basematerials'][basematerialsData['id']] = basematerialsData;
            }

            resourcesData['texture2d'] = {};
            var textures2DNodes = resourcesNode.querySelectorAll('texture2d');

            for (_v = 0; _v < textures2DNodes.length; _v++) {
                var textures2DNode = textures2DNodes[_v];
                var texture2DData = parseTexture2DNode(textures2DNode);
                resourcesData['texture2d'][texture2DData['id']] = texture2DData;
            }

            resourcesData['colorgroup'] = {};
            var colorGroupNodes = resourcesNode.querySelectorAll('colorgroup');

            for (_w = 0; _w < colorGroupNodes.length; _w++) {
                var colorGroupNode = colorGroupNodes[_w];
                var colorGroupData = parseColorGroupNode(colorGroupNode);
                resourcesData['colorgroup'][colorGroupData['id']] = colorGroupData;
            }

            resourcesData['pbmetallicdisplayproperties'] =