import three.AddOperation;
import three.BackSide;
import three.BufferGeometry;
import three.ClampToEdgeWrapping;
import three.Color;
import three.DoubleSide;
import three.EquirectangularReflectionMapping;
import three.EquirectangularRefractionMapping;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.FrontSide;
import three.LineBasicMaterial;
import three.LineSegments;
import three.Loader;
import three.Mesh;
import three.MeshPhongMaterial;
import three.MeshPhysicalMaterial;
import three.MeshStandardMaterial;
import three.MirroredRepeatWrapping;
import three.Points;
import three.PointsMaterial;
import three.RepeatWrapping;
import three.SRGBColorSpace;
import three.TextureLoader;
import three.Vector2;

import lwo.IFFParser;

var _lwoTree:IFFParser;

class LWOLoader extends Loader {

    public function new(manager:LoaderManager, parameters:Dynamic = null) {
        super(manager);

        if (parameters == null) parameters = {};

        if (parameters.resourcePath != null) {
            this.resourcePath = parameters.resourcePath;
        } else {
            this.resourcePath = "";
        }
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        var scope:LWOLoader = this;
        var path:String = (scope.path == "") ? extractParentUrl(url, "Objects") : scope.path;
        var modelName:String = url.split(path).pop().split(".")[0];

        var loader:FileLoader = new FileLoader(this.manager);
        loader.setPath(scope.path);
        loader.setResponseType("arraybuffer");

        loader.load(url, function (buffer:ArrayBuffer):Void {
            try {
                onLoad(scope.parse(buffer, path, modelName));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(iffBuffer:ArrayBuffer, path:String, modelName:String):Dynamic {
        _lwoTree = new IFFParser().parse(iffBuffer);

        var textureLoader:TextureLoader = new TextureLoader(this.manager).setPath(this.resourcePath || path).setCrossOrigin(this.crossOrigin);

        return new LWOTreeParser(textureLoader).parse(modelName);
    }
}

class LWOTreeParser {

    private var textureLoader:TextureLoader;
    private var materials:Array<Dynamic>;
    private var defaultLayerName:String;
    private var meshes:Array<Mesh>;

    public function new(textureLoader:TextureLoader) {
        this.textureLoader = textureLoader;
    }

    public function parse(modelName:String):Dynamic {
        this.materials = new MaterialParser(this.textureLoader).parse();
        this.defaultLayerName = modelName;

        this.meshes = this.parseLayers();

        return {
            materials: this.materials,
            meshes: this.meshes,
        };
    }

    private function parseLayers():Array<Mesh> {
        var meshes:Array<Mesh> = [];
        var finalMeshes:Array<Mesh> = [];

        var geometryParser:GeometryParser = new GeometryParser();

        var scope:LWOTreeParser = this;
        for (layer in _lwoTree.layers) {
            var geometry:BufferGeometry = geometryParser.parse(layer.geometry, layer);
            var mesh:Mesh = scope.parseMesh(geometry, layer);

            meshes[layer.number] = mesh;

            if (layer.parent == -1) {
                finalMeshes.push(mesh);
            } else {
                meshes[layer.parent].add(mesh);
            }
        }

        this.applyPivots(finalMeshes);

        return finalMeshes;
    }

    private function parseMesh(geometry:BufferGeometry, layer:Dynamic):Mesh {
        var mesh:Mesh;
        var materials:Dynamic = this.getMaterials(geometry.userData.matNames, layer.geometry.type);

        if (layer.geometry.type == "points") {
            mesh = new Points(geometry, materials);
        } else if (layer.geometry.type == "lines") {
            mesh = new LineSegments(geometry, materials);
        } else {
            mesh = new Mesh(geometry, materials);
        }

        if (layer.name != null) {
            mesh.name = layer.name;
        } else {
            mesh.name = this.defaultLayerName + "_layer_" + layer.number;
        }

        mesh.userData.pivot = layer.pivot;

        return mesh;
    }

    private function applyPivots(meshes:Array<Mesh>):Void {
        for (mesh in meshes) {
            mesh.traverse(function (child:Mesh):Void {
                var pivot:Array<Float> = child.userData.pivot;

                child.position.x += pivot[0];
                child.position.y += pivot[1];
                child.position.z += pivot[2];

                if (child.parent != null) {
                    var parentPivot:Array<Float> = child.parent.userData.pivot;

                    child.position.x -= parentPivot[0];
                    child.position.y -= parentPivot[1];
                    child.position.z -= parentPivot[2];
                }
            });
        }
    }

    private function getMaterials(namesArray:Array<String>, type:String):Dynamic {
        var materials:Array<Dynamic> = [];

        var scope:LWOTreeParser = this;
        for (name in namesArray) {
            materials.push(scope.getMaterialByName(name));
        }

        if (type == "points" || type == "lines") {
            for (i in 0...materials.length) {
                var mat:Dynamic = materials[i];
                var spec:Dynamic = {
                    color: mat.color,
                };

                if (type == "points") {
                    spec.size = 0.1;
                    spec.map = mat.map;
                    materials[i] = new PointsMaterial(spec);
                } else if (type == "lines") {
                    materials[i] = new LineBasicMaterial(spec);
                }
            }
        }

        var filtered:Array<Dynamic> = materials.filter(function (m:Dynamic):Bool {
            return m != null;
        });

        if (filtered.length == 1) return filtered[0];

        return materials;
    }

    private function getMaterialByName(name:String):Dynamic {
        return this.materials.filter(function (m:Dynamic):Bool {
            return m.name == name;
        })[0];
    }
}

class MaterialParser {

    private var textureLoader:TextureLoader;
    private var textures:Dynamic;

    public function new(textureLoader:TextureLoader) {
        this.textureLoader = textureLoader;
    }

    public function parse():Array<Dynamic> {
        var materials:Array<Dynamic> = [];
        this.textures = {};

        for (name in _lwoTree.materials) {
            if (_lwoTree.format == "LWO3") {
                materials.push(this.parseMaterial(_lwoTree.materials[name], name, _lwoTree.textures));
            } else if (_lwoTree.format == "LWO2") {
                materials.push(this.parseMaterialLwo2(_lwoTree.materials[name], name, _lwoTree.textures));
            }
        }

        return materials;
    }

    private function parseMaterial(materialData:Dynamic, name:String, textures:Dynamic):Dynamic {
        var params:Dynamic = {
            name: name,
            side: this.getSide(materialData.attributes),
            flatShading: this.getSmooth(materialData.attributes),
        };

        var connections:Dynamic = this.parseConnections(materialData.connections, materialData.nodes);
        var maps:Dynamic = this.parseTextureNodes(connections.maps);
        this.parseAttributeImageMaps(connections.attributes, textures, maps, materialData.maps);
        var attributes:Dynamic = this.parseAttributes(connections.attributes, maps);
        this.parseEnvMap(connections, maps, attributes);

        params = haxe.ds.ObjectUtil.copy(maps, params);
        params = haxe.ds.ObjectUtil.copy(params, attributes);

        var materialType:Class<Dynamic> = this.getMaterialType(connections.attributes);

        if (materialType != MeshPhongMaterial) delete params.refractionRatio;

        return Type.createInstance(materialType, [params]);
    }

    private function parseMaterialLwo2(materialData:Dynamic, name:String, textures:Dynamic):Dynamic {
        var params:Dynamic = {
            name: name,
            side: this.getSide(materialData.attributes),
            flatShading: this.getSmooth(materialData.attributes),
        };

        var attributes:Dynamic = this.parseAttributes(materialData.attributes, {});
        params = haxe.ds.ObjectUtil.copy(params, attributes);

        return new MeshPhongMaterial(params);
    }

    private function getSide(attributes:Dynamic):Int {
        if (attributes.side == null) return BackSide;

        switch (attributes.side) {
            case 0:
            case 1:
                return BackSide;
            case 2: return FrontSide;
            case 3: return DoubleSide;
            default: return BackSide;
        }
    }

    private function getSmooth(attributes:Dynamic):Bool {
        if (attributes.smooth == null) return true;
        return !attributes.smooth;
    }

    private function parseConnections(connections:Dynamic, nodes:Dynamic):Dynamic {
        var materialConnections:Dynamic = {
            maps: {}
        };

        var inputName:Array<String> = connections.inputName;
        var inputNodeName:Array<String> = connections.inputNodeName;
        var nodeName:Array<String> = connections.nodeName;

        var scope:MaterialParser = this;
        for (i in 0...inputName.length) {
            if (inputName[i] == "Material") {
                var matNode:Dynamic = scope.getNodeByRefName(inputNodeName[i], nodes);
                materialConnections.attributes = matNode.attributes;
                materialConnections.envMap = matNode.fileName;
                materialConnections.name = inputNodeName[i];
            }
        }

        for (i in 0...nodeName.length) {
            if (nodeName[i] == materialConnections.name) {
                materialConnections.maps[inputName[i]] = scope.getNodeByRefName(inputNodeName[i], nodes);
            }
        }

        return materialConnections;
    }

    private function getNodeByRefName(refName:String, nodes:Dynamic):Dynamic {
        for (name in nodes) {
            if (nodes[name].refName == refName) return nodes[name];
        }

        return null;
    }

    private function parseTextureNodes(textureNodes:Dynamic):Dynamic {
        var maps:Dynamic = {};

        for (name in textureNodes) {
            var node:Dynamic = textureNodes[name];
            var path:String = node.fileName;

            if (path == null) return null;

            var texture:Texture = this.loadTexture(path);

            if (node.widthWrappingMode != null) texture.wrapS = this.getWrappingType(node.widthWrappingMode);
            if (node.heightWrappingMode != null) texture.wrapT = this.getWrappingType(node.heightWrappingMode);

            switch (name) {
                case "Color":
                    maps.map = texture;
                    maps.map.colorSpace = SRGBColorSpace;
                    break;
                case "Roughness":
                    maps.roughnessMap = texture;
                    maps.roughness = 1;
                    break;
                case "Specular":
                    maps.specularMap = texture;
                    maps.specularMap.colorSpace = SRGBColorSpace;
                    maps.specular = 0xffffff;
                    break;
                case "Luminous":
                    maps.emissiveMap = texture;
                    maps.emissiveMap.colorSpace = SRGBColorSpace;
                    maps.emissive = 0x808080;
                    break;
                case "Luminous Color":
                    maps.emissive = 0x808080;
                    break;
                case "Metallic":
                    maps.metalnessMap = texture;
                    maps.metalness = 1;
                    break;
                case "Transparency":
                case "Alpha":
                    maps.alphaMap = texture;
                    maps.transparent = true;
                    break;
                case "Normal":
                    maps.normalMap = texture;
                    if (node.amplitude != null) maps.normalScale = new Vector2(node.amplitude, node.amplitude);
                    break;
                case "Bump":
                    maps.bumpMap = texture;
                    break;
            }
        }

        if (maps.roughnessMap != null && maps.specularMap != null) delete maps.specularMap;

        return maps;
    }

    private function parseAttributeImageMaps(attributes:Dynamic, textures:Dynamic, maps:Dynamic, materialMaps:Dynamic):Void {
        for (name in attributes) {
            var attribute:Dynamic = attributes[name];

            if (attribute.maps != null) {
                var mapData:Dynamic = attribute.maps[0];
                var path:String = this.getTexturePathByIndex(mapData.imageIndex, textures);

                if (path == null) return;

                var texture:Texture = this.loadTexture(path);

                if (mapData.wrap != null) texture.wrapS = this.getWrappingType(mapData.wrap.w);
                if (mapData.wrap != null) texture.wrapT = this.getWrappingType(mapData.wrap.h);

                switch (name) {
                    case "Color":
                        maps.map = texture;
                        maps.map.colorSpace = SRGBColorSpace;
                        break;
                    case "Diffuse":
                        maps.aoMap = texture;
                        break;
                    case "Roughness":
                        maps.roughnessMap = texture;
                        maps.roughness = 1;
                        break;
                    case "Specular":
                        maps.specularMap = texture;
                        maps.specularMap.colorSpace = SRGBColorSpace;
                        maps.specular = 0xffffff;
                        break;
                    case "Luminosity":
                        maps.emissiveMap = texture;
                        maps.emissiveMap.colorSpace = SRGBColorSpace;
                        maps.emissive = 0x808080;
                        break;
                    case "Metallic":
                        maps.metalnessMap = texture;
                        maps.metalness = 1;
                        break;
                    case "Transparency":
                    case "Alpha":
                        maps.alphaMap = texture;
                        maps.transparent = true;
                        break;
                    case "Normal":
                        maps.normalMap = texture;
                        break;
                    case "Bump":
                        maps.bumpMap = texture;
                        break;
                }
            }
        }
    }

    private function parseAttributes(attributes:Dynamic, maps:Dynamic):Dynamic {
        var params:Dynamic = {};

        if (attributes.Color != null && maps.map == null) {
            params.color = new Color().fromArray(attributes.Color.value);
        } else {
            params.color = new Color();
        }

        if (attributes.Transparency != null && attributes.Transparency.value != 0) {
            params.opacity = 1 - attributes.Transparency.value;
            params.transparent = true;
        }

        if (attributes["Bump Height"] != null) params.bumpScale = attributes["Bump Height"].value * 0.1;

        this.parsePhysicalAttributes(params, attributes, maps);
        this.parseStandardAttributes(params, attributes, maps);
        this.parsePhongAttributes(params, attributes, maps);

        return params;
    }

    private function parsePhysicalAttributes(params:Dynamic, attributes:Dynamic, maps:Dynamic):Void {
        if (attributes.Clearcoat != null && attributes.Clearcoat.value > 0) {
            params.clearcoat = attributes.Clearcoat.value;

            if (attributes["Clearcoat Gloss"] != null) {
                params.clearcoatRoughness = 0.5 * (1 - attributes["Clearcoat Gloss"].value);
            }
        }
    }

    private function parseStandardAttributes(params:Dynamic, attributes:Dynamic, maps:Dynamic):Void {
        if (attributes.Luminous != null) {
            params.emissiveIntensity = attributes.Luminous.value;

            if (attributes["Luminous Color"] != null && maps.emissive == null) {
                params.emissive = new Color().fromArray(attributes["Luminous Color"].value);
            } else {
                params.emissive = new Color(0x808080);
            }
        }

        if (attributes.Roughness != null && maps.roughnessMap == null) params.roughness = attributes.Roughness.value;
        if (attributes.Metallic != null && maps.metalnessMap == null) params.metalness = attributes.Metallic.value;
    }

    private function parsePhongAttributes(params:Dynamic, attributes:Dynamic, maps:Dynamic):Void {
        if (attributes["Refraction Index"] != null) params.refractionRatio = 0.98 / attributes["Refraction Index"].value;

        if (attributes.Diffuse != null) params.color.multiplyScalar(attributes.Diffuse.value);

        if (attributes.Reflection != null) {
            params.reflectivity = attributes.Reflection.value;
            params.combine = AddOperation;
        }

        if (attributes.Luminosity != null) {
            params.emissiveIntensity = attributes.Luminosity.value;

            if (maps.emissiveMap == null && maps.map == null) {
                params.emissive = params.color;
            } else {
                params.emissive = new Color(0x808080);
            }
        }

        if (attributes.Roughness == null && attributes.Specular != null && maps.specularMap == null) {
            if (attributes["Color Highlight"] != null) {
                params.specular = new Color().setScalar(attributes.Specular.value).lerp(params.color.clone().multiplyScalar(attributes.Specular.value), attributes["Color Highlight"].value);
            } else {
                params.specular = new Color().setScalar(attributes.Specular.value);
            }
        }

        if (params.specular != null && attributes.Glossiness != null) params.shininess = 7 + Math.pow(2, attributes.Glossiness.value * 12 + 2);
    }

    private function parseEnvMap(connections:Dynamic, maps:Dynamic, attributes:Dynamic):Void {
        if (connections.envMap != null) {
            var envMap:Texture = this.loadTexture(connections.envMap);

            if (attributes.transparent && attributes.opacity < 0.999) {
                envMap.mapping = EquirectangularRefractionMapping;

                if (attributes.reflectivity != null) {
                    delete attributes.reflectivity;
                    delete attributes.combine;
                }

                if (attributes.metalness != null) {
                    attributes.metalness = 1;
                }

                attributes.opacity = 1;
            } else {
                envMap.mapping = EquirectangularReflectionMapping;
            }

            maps.envMap = envMap;
        }
    }

    private function getTexturePathByIndex(index:Int, textures:Dynamic):String {
        var fileName:String = "";

        if (textures == null) return fileName;

        for (texture in textures) {
            if (texture.index == index) fileName = texture.fileName;
        }

        return fileName;
    }

    private function loadTexture(path:String):Texture {
        if (path == null) return null;

        var texture:Texture = this.textureLoader.load(
            path,
            null,
            null,
            function():Void {
                trace("LWOLoader: non-standard resource hierarchy. Use `resourcePath` parameter to specify root content directory.");
            }
        );

        return texture;
    }

    private function getWrappingType(num:Int):Int {
        switch (num) {
            case 0:
                trace("LWOLoader: \"Reset\" texture wrapping type is not supported in three.js");
                return ClampToEdgeWrapping;
            case 1: return RepeatWrapping;
            case 2: return MirroredRepeatWrapping;
            case 3: return ClampToEdgeWrapping;
            default: return ClampToEdgeWrapping;
        }
    }

    private function getMaterialType(nodeData:Dynamic):Class<Dynamic> {
        if (nodeData.Clearcoat != null && nodeData.Clearcoat.value > 0) return MeshPhysicalMaterial;
        if (nodeData.Roughness != null) return MeshStandardMaterial;
        return MeshPhongMaterial;
    }
}

class GeometryParser {

    public function parse(geoData:Dynamic, layer:Dynamic):BufferGeometry {
        var geometry:BufferGeometry = new BufferGeometry();

        geometry.setAttribute("position", new Float32BufferAttribute(geoData.points, 3));

        var indices:Array<Int> = this.splitIndices(geoData.vertexIndices, geoData.polygonDimensions);
        geometry.setIndex(indices);

        this.parseGroups(geometry, geoData);

        geometry.computeVertexNormals();

        this.parseUVs(geometry, layer, indices);
        this.parseMorphTargets(geometry, layer, indices);

        geometry.translate(-layer.pivot[0], -layer.pivot[1], -layer.pivot[2]);

        return geometry;
    }

    private function splitIndices(indices:Array<Int>, polygonDimensions:Array<Int>):Array<Int> {
        var remappedIndices:Array<Int> = [];

        var i:Int = 0;
        for (dim in polygonDimensions) {
            if (dim < 4) {
                for (k in 0...dim) remappedIndices.push(indices[i + k]);
            } else if (dim == 4) {
                remappedIndices.push(
                    indices[i],
                    indices[i + 1],
                    indices[i + 2],
                    indices[i],
                    indices[i + 2],
                    indices[i + 3]
                );
            } else if (dim > 4) {
                for (k in 1...dim - 1) {
                    remappedIndices.push(indices[i], indices[i + k], indices[i + k + 1]);
                }
                trace("LWOLoader: polygons with greater than 4 sides are not supported");
            }

            i += dim;
        }

        return remappedIndices;
    }

    private function parseGroups(geometry:BufferGeometry, geoData:Dynamic):Void {
        var tags:Dynamic = _lwoTree.tags;
        var matNames:Array<String> = [];

        var elemSize:Int = 3;
        if (geoData.type == "lines") elemSize = 2;
        if (geoData.type == "points") elemSize = 1;

        var remappedIndices:Array<Int> = this.splitMaterialIndices(geoData.polygonDimensions, geoData.materialIndices);

        var indexNum:Int = 0;
        var indexPairs:Dynamic = {};

        var prevMaterialIndex:Int;
        var materialIndex:Int;

        var prevStart:Int = 0;
        var currentCount:Int = 0;

        for (i in 0...remappedIndices.length / 2) {
            materialIndex = remappedIndices[i * 2 + 1];

            if (i == 0) matNames[indexNum] = tags[materialIndex];

            if (prevMaterialIndex == null) prevMaterialIndex = materialIndex;

            if (materialIndex != prevMaterialIndex) {
                var currentIndex:Int;
                if (indexPairs[tags[prevMaterialIndex]] != null) {
                    currentIndex = indexPairs[tags[prevMaterialIndex]];
                } else {
                    currentIndex = indexNum;
                    indexPairs[tags[prevMaterialIndex]] = indexNum;
                    matNames[indexNum] = tags[prevMaterialIndex];
                    indexNum++;
                }

                geometry.addGroup(prevStart, currentCount, currentIndex);

                prevStart += currentCount;

                prevMaterialIndex = materialIndex;
                currentCount = 0;
            }

            currentCount += elemSize;
        }

        if (geometry.groups.length > 0) {
            var currentIndex:Int;
            if (indexPairs[tags[materialIndex]] != null) {
                currentIndex = indexPairs[tags[materialIndex]];
            } else {
                currentIndex = indexNum;
                indexPairs[tags[materialIndex]] = indexNum;
                matNames[indexNum] = tags[materialIndex];
            }

            geometry.addGroup(prevStart, currentCount, currentIndex);
        }

        geometry.userData.matNames = matNames;
    }

    private function splitMaterialIndices(polygonDimensions:Array<Int>, indices:Array<Int>):Array<Int> {
        var remappedIndices:Array<Int> = [];

        for (i in 0...polygonDimensions.length) {
            var dim:Int = polygonDimensions[i];
            if (dim <= 3) {
                remappedIndices.push(indices[i * 2], indices[i * 2 + 1]);
            } else if (dim == 4) {
                remappedIndices.push(indices[i * 2], indices[i * 2 + 1], indices[i * 2], indices[i * 2 + 1]);
            } else {
                for (k in 0...dim - 2) {
                    remappedIndices.push(indices[i * 2], indices[i * 2 + 1]);
                }
            }
        }

        return remappedIndices;
    }

    private function parseUVs(geometry:BufferGeometry, layer:Dynamic, indices:Array<Int>):Void {
        var remappedUVs:Array<Float> = Array<Float>(geometry.attributes.position.count * 2);

        for (name in layer.uvs) {
            var uvs:Array<Float> = layer.uvs[name].uvs;
            var uvIndices:Array<Int> = layer.uvs[name].uvIndices;

            for (j in 0...uvIndices.length) {
                remappedUVs[uvIndices[j] * 2] = uvs[j * 2];
                remappedUVs[uvIndices[j] * 2 + 1] = uvs[j * 2 + 1];
            }
        }

        geometry.setAttribute("uv", new Float32BufferAttribute(remappedUVs, 2));
    }

    private function parseMorphTargets(geometry:BufferGeometry, layer:Dynamic, indices:Array<Int>):Void {
        var num:Int = 0;
        for (name in layer.morphTargets) {
            var remappedPoints:Array<Float> = geometry.attributes.position.array.slice();

            if (geometry.morphAttributes.position == null) geometry.morphAttributes.position = [];

            var morphPoints:Array<Float> = layer.morphTargets[name].points;
            var morphIndices:Array<Int> = layer.morphTargets[name].indices;
            var type:String = layer.morphTargets[name].type;

            for (j in 0...morphIndices.length) {
                if (type == "relative") {
                    remappedPoints[morphIndices[j] * 3] += morphPoints[j * 3];
                    remappedPoints[morphIndices[j] * 3 + 1] += morphPoints[j * 3 + 1];
                    remappedPoints[morphIndices[j] * 3 + 2] += morphPoints[j * 3 + 2];
                } else {
                    remappedPoints[morphIndices[j] * 3] = morphPoints[j * 3];
                    remappedPoints[morphIndices[j] * 3 + 1] = morphPoints[j * 3 + 1];
                    remappedPoints[morphIndices[j] * 3 + 2] = morphPoints[j * 3 + 2];
                }
            }

            geometry.morphAttributes.position[num] = new Float32BufferAttribute(remappedPoints, 3);
            geometry.morphAttributes.position[num].name = name;

            num++;
        }

        geometry.morphTargetsRelative = false;
    }
}

function extractParentUrl(url:String, dir:String):String {
    var index:Int = url.indexOf(dir);

    if (index == -1) return "./";

    return url.slice(0, index);
}