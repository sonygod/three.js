import haxe.io.Bytes;
import js.Browser;
import js.html.Array;
import js.html.Document;
import js.html.Window;

class LWOLoader {
    public function new(manager:Dynamic, parameters:Dynamic) {
        #if js
        if (parameters == null) parameters = { };
        #end
        #if js
        super(manager);
        #end
        #if js
        this.resourcePath = (parameters.resourcePath != null) ? parameters.resourcePath : "";
        #end
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
        #if js
        var scope = this;
        var path = (scope.path == "") ? extractParentUrl(url, "Objects") : scope.path;
        var modelName = url.split(path).pop().split(".").__get(0);
        var loader = new FileLoader(this.manager);
        loader.setPath(scope.path);
        loader.setResponseType("arraybuffer");
        loader.load(url, function(buffer) {
            try {
                onLoad(scope.parse(buffer, path, modelName));
            } catch (e) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
        #end
    }

    public function parse(iffBuffer:Bytes, path:String, modelName:String):Dynamic {
        #if js
        _lwoTree = new IFFParser().parse(iffBuffer);
        var textureLoader = new TextureLoader(this.manager);
        textureLoader.setPath(this.resourcePath != null ? this.resourcePath : path);
        textureLoader.setCrossOrigin(this.crossOrigin);
        return new LWOTreeParser(textureLoader).parse(modelName);
        #end
    }
}

class LWOTreeParser {
    public var textureLoader:Dynamic;

    public function new(textureLoader:Dynamic) {
        this.textureLoader = textureLoader;
    }

    public function parse(modelName:String):Dynamic {
        #if js
        this.materials = new MaterialParser(this.textureLoader).parse();
        this.defaultLayerName = modelName;
        this.meshes = this.parseLayers();
        return { materials : this.materials, meshes : this.meshes };
        #end
    }

    public function parseLayers():Dynamic {
        #if js
        var meshes = [];
        var finalMeshes = [];
        var geometryParser = new GeometryParser();
        _lwoTree.layers.forEach(function(layer) {
            var geometry = geometryParser.parse(layer.geometry, layer);
            var mesh = this.parseMesh(geometry, layer);
            meshes[layer.number] = mesh;
            if (layer.parent == -1) finalMeshes.push(mesh);
            else meshes[layer.parent].add(mesh);
        });
        this.applyPivots(finalMeshes);
        return finalMeshes;
        #end
    }

    public function parseMesh(geometry:Dynamic, layer:Dynamic):Dynamic {
        #if js
        var mesh;
        var materials = this.getMaterials(geometry.userData.matNames, layer.geometry.type);
        if (layer.geometry.type == "points") mesh = new Points(geometry, materials);
        else if (layer.geometry.type == "lines") mesh = new LineSegments(geometry, materials);
        else mesh = new Mesh(geometry, materials);
        if (layer.name != null) mesh.name = layer.name;
        else mesh.name = this.defaultLayerName + "_layer_" + layer.number;
        mesh.userData.pivot = layer.pivot;
        return mesh;
        #end
    }

    public function applyPivots(meshes:Array<Dynamic>):Void {
        #if js
        meshes.forEach(function(mesh) {
            mesh.traverse(function(child) {
                var pivot = child.userData.pivot;
                child.position.x += pivot.__get(0);
                child.position.y += pivot.__get(1);
                child.position.z += pivot.__get(2);
                if (child.parent != null) {
                    var parentPivot = child.parent.userData.pivot;
                    child.position.x -= parentPivot.__get(0);
                    child.position.y -= parentPivot.__get(1);
                    child.position.z -= parentPivot.__get(2);
                }
            });
        });
        #end
    }

    public function getMaterials(namesArray:Array<String>, type:String):Dynamic {
        #if js
        var materials = [];
        namesArray.forEach(function(name, i) {
            materials[i] = this.getMaterialByName(name);
        });
        if (type == "points" || type == "lines") {
            materials.forEach(function(mat, i) {
                var spec = { };
                if (type == "points") {
                    spec.size = 0.1;
                    spec.map = mat.map;
                    materials[i] = new PointsMaterial(spec);
                } else if (type == "lines") {
                    materials[i] = new LineBasicMaterial(spec);
                }
            });
        }
        var filtered = materials.filter(function(m) {
            return m != null;
        });
        if (filtered.length == 1) return filtered.__get(0);
        return materials;
        #end
    }

    public function getMaterialByName(name:String):Dynamic {
        #if js
        return this.materials.filter(function(m) {
            return m.name == name;
        }).__get(0);
        #end
    }
}

class MaterialParser {
    public var textureLoader:Dynamic;

    public function new(textureLoader:Dynamic) {
        this.textureLoader = textureLoader;
    }

    public function parse():Dynamic {
        #if js
        var materials = [];
        var textures = { };
        for (var name in _lwoTree.materials) {
            if (_lwoTree.format == "LWO3") {
                materials.push(this.parseMaterial(_lwoTree.materials.__get(name), name, _lwoTree.textures));
            } else if (_lwoTree.format == "LWO2") {
                materials.push(this.parseMaterialLwo2(_lwoTree.materials.__get(name), name, _lwoTree.textures));
            }
        }
        return materials;
        #end
    }

    public function parseMaterial(materialData:Dynamic, name:String, textures:Dynamic):Dynamic {
        #if js
        var params = { };
        params.name = name;
        params.side = this.getSide(materialData.attributes);
        params.flatShading = this.getSmooth(materialData.attributes);
        var connections = this.parseConnections(materialData.connections, materialData.nodes);
        var maps = this.parseTextureNodes(connections.maps);
        this.parseAttributeImageMaps(connections.attributes, textures, maps, materialData.maps);
        var attributes = this.parseAttributes(connections.attributes, maps);
        this.parseEnvMap(connections, maps, attributes);
        params = Object.assign(maps, params);
        params = Object.assign(params, attributes);
        var materialType = this.getMaterialType(connections.attributes);
        if (materialType != MeshPhongMaterial) delete params.refractionRatio;
        return new materialType(params);
        #end
    }

    public function parseMaterialLwo2(materialData:Dynamic, name:String, textures:Dynamic):Dynamic {
        #if js
        var params = { };
        params.name = name;
        params.side = this.getSide(materialData.attributes);
        params.flatShading = this.getSmooth(materialData.attributes);
        var attributes = this.parseAttributes(materialData.attributes, { });
        params = Object.assign(params, attributes);
        return new MeshPhongMaterial(params);
        #end
    }

    public function getSide(attributes:Dynamic):Dynamic {
        #if js
        if (attributes.side == null) return BackSide;
        switch (attributes.side) {
            case 0:
            case 1:
                return BackSide;
            case 2:
                return FrontSide;
            case 3:
                return DoubleSide;
        }
        #end
    }

    public function getSmooth(attributes:Dynamic):Bool {
        #if js
        if (attributes.smooth == null) return true;
        return !attributes.smooth;
        #end
    }

    public function parseConnections(connections:Dynamic, nodes:Dynamic):Dynamic {
        #if js
        var materialConnections = { };
        var inputName = connections.inputName;
        var inputNodeName = connections.inputNodeName;
        var nodeName = connections.nodeName;
        var scope = this;
        inputName.forEach(function(name, index) {
            if (name == "Material") {
                var matNode = scope.getNodeByRefName(inputNodeName.__get(index), nodes);
                materialConnections.attributes = matNode.attributes;
                materialConnections.envMap = matNode.fileName;
                materialConnections.name = inputNodeName.__get(index);
            }
        });
        nodeName.forEach(function(name, index) {
            if (name == materialConnections.name) {
                materialConnections.maps[inputName.__get(index)] = scope.getNodeByRefName(inputNodeName.__get(index), nodes);
            }
        });
        return materialConnections;
        #end
    }

    public function getNodeByRefName(refName:String, nodes:Dynamic):Dynamic {
        #if js
        for (var name in nodes) {
            if (nodes.__get(name).refName == refName) return nodes.__get(name);
        }
        #end
    }

    public function parseTextureNodes(textureNodes:Dynamic):Dynamic {
        #if js
        var maps = { };
        for (var name in textureNodes) {
            var node = textureNodes.__get(name);
            var path = node.fileName;
            if (path == null) return;
            var texture = this.loadTexture(path);
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
        #end
    }

    public function parseAttributeImageMaps(attributes:Dynamic, textures:Dynamic, maps:Dynamic):Void {
        #if js
        for (var name in attributes) {
            var attribute = attributes.__get(name);
            if (attribute.maps != null) {
                var mapData = attribute.maps.__get(0);
                var path = this.getTexturePathByIndex(mapData.imageIndex, textures);
                if (path == null) return;
                var texture = this.loadTexture(path);
                if (mapData.wrap != null) {
                    texture.wrapS = this.getWrappingType(mapData.wrap.w);
                    texture.wrapT = this.getWrappingType(mapData.wrap.h);
                }
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
        #end
    }

    public function parseAttributes(attributes:Dynamic, maps:Dynamic):Dynamic {
        #if js
        var params = { };
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
        #end
    }

    public function parsePhysicalAttributes(params:Dynamic, attributes:Dynamic, maps:Dynamic):Void {
        #if js
        if (attributes.Clearcoat != null && attributes.Clearcoat.value > 0) {
            params.clearcoat = attributes.Clearcoat.value;
            if (attributes["Clearcoat Gloss"] != null) {
                params.clearcoatRoughness = 0.5 * (1 - attributes["Clearcoat Gloss"].value);
            }
        }
        #end
    }

    public function parseStandardAttributes(params:Dynamic, attributes:Dynamic, maps:Dynamic):Void {
        #if js
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
        #end
    }

    public function parsePhongAttributes(params:Dynamic, attributes:Dynamic, maps:Dynamic):Void {
        #if js
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
        #end
    }

    public function parseEnvMap(connections:Dynamic, maps:Dynamic, attributes:Dynamic):Void {
        #if js
        if (connections.envMap != null) {
            var envMap = this.loadTexture(connections.envMap);
            if (attributes.transparent != null && attributes.opacity < 0.999) {
                envMap.mapping = EquirectangularRef
                Mapping;
                if (attributes.reflectivity != null) {
                    delete attributes.reflectivity;
                    delete attributes.combine;
                }
                if (attributes.metalness != null) {
                    attributes.metalness = 1;
                }
                attributes.opacity = 1;
            } else envMap.mapping = EquirectangularReflectionMapping;
            maps.envMap = envMap;
        }
        #end
    }

    public function getTexturePathByIndex(index:Int):String {
        #if js
        var fileName = "";
        if (_lwoTree.textures == null) return fileName;
        _lwoTree.textures.forEach(function(texture) {
            if (texture.index == index) fileName = texture.fileName;
        });
        return fileName;
        #end
    }

    public function loadTexture(path:String):Dynamic {
        #if js
        if (path == null) return null;
        var texture = this.textureLoader.load(path, undefined, undefined, function() {
            trace("LWOLoader: non-standard resource hierarchy. Use `resourcePath` parameter to specify root content directory.");
        });
        return texture;
        #end
    }

    public function getWrappingType(num:Int):Dynamic {
        #if js
        switch (num) {
            case 0:
                trace("LWOLoader: \"Reset\" texture wrapping type is not supported in three.js");
                return ClampToEdgeWrapping;
            case 1:
                return RepeatWrapping;
            case 2:
                return MirroredRepeatWrapping;
            case 3:
                return ClampToEdgeWrapping;
        }
        #end
    }

    public function getMaterialType(nodeData:Dynamic):Dynamic {
        #if js
        if (nodeData.Clearcoat != null && nodeData.Clearcoat.value > 0) return MeshPhysicalMaterial;
        if (nodeData.Roughness != null) return MeshStandardMaterial;
        return MeshPhongMaterial;
        #end
    }
}

class GeometryParser {
    public function parse(geoData:Dynamic, layer:Dynamic):Dynamic {
        #if js
        var geometry = new BufferGeometry();
        geometry.setAttribute("position", new Float32BufferAttribute(geoData.points, 3));
        var indices = this.splitIndices(geoData.vertexIndices, geoData.polygonDimensions);
        geometry.setIndex(indices);
        this.parseGroups(geometry, geoData);
        geometry.computeVertexNormals();
        this.parseUVs(geometry, layer, indices);
        this.parseMorphTargets(geometry, layer, indices);
        geometry.translate(-layer.pivot.__get(0), -layer.pivot.__get(1), -layer.pivot.__get(2));
        return geometry;
        #end
    }

    public function splitIndices(indices:Dynamic, polygonDimensions:Dynamic):Dynamic {
        #if js
        var remappedIndices = [];
        var i = 0;
        polygonDimensions.forEach(function(dim) {
            if (dim < 4) {
                for (var k = 0; k < dim; k++) remappedIndices.push(indices[i + k]);
            } else if (dim == 4) {
                remappedIndices.push(indices[i], indices[i + 1], indices[i + 2], indices[i], indices[i + 2], indices[i + 3]);
            } else if (dim > 4) {
                for (var k = 1; k < dim - 1; k++) {
                    remappedIndices.push(indices[i], indices[i + k], indices[i + k + 1]);
                }
                trace("LWOLoader: polygons with greater than 4 sides are not supported");
            }
            i += dim;
        });
        return remappedIndices;
        #end
    }

    public function parseGroups(geometry:Dynamic, geoData:Dynamic):Void {
        #if js
        var tags = _lwoTree.tags;
        var matNames = [];
        var elemSize = 3;
        if (geoData.type == "lines") elemSize = 2;
        if (geoData.type == "points") elemSize = 1;
        var remappedIndices = this.splitMaterialIndices(geoData.polygonDimensions, geoData.materialIndices);
        var indexNum = 0;
        var indexPairs = { };
        var prevMaterialIndex;
        var materialIndex;
        var prevStart = 0;
        var currentCount = 0;
        for (var i = 0; i < remappedIndices.length; i += 2) {
            materialIndex = remappedIndices[i + 1];
            if (i == 0) matNames[indexNum] = tags[materialIndex];
            if (prevMaterialIndex == null) prevMaterialIndex = materialIndex;
            if (materialIndex != prevMaterialIndex) {
                var currentIndex;
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
            var currentIndex;
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
        #end
    }

    public function splitMaterialIndices(polygonDimensions:Dynamic, indices:Dynamic):Dynamic {
        #if js
        var remappedIndices = [];
        polygonDimensions.forEach(function(dim, i) {
            if (dim <= 3) {
                remappedIndices.push(indices[i * 2], indices[i * 2 + 1]);
            } else if (dim == 4) {
                remappedIndices.push(indices[i * 2], indices[i * 2 + 1], indices[i * 2], indices[i * 2 + 1]);
            } else {
                for (var k = 0; k < dim - 2; k++) {
                    remappedIndices.push(indices[i * 2], indices[i * 2 + 1]);
                }
            }
        });
        return remappedIndices;
        #end
    }

    public function parseUVs(geometry:Dynamic, layer:Dynamic):Void {
        #if js
        var remappedUVs = Array.from(Array(geometry.attributes.position.count * 2), function() {
            return 0;
        });
        for (var name in layer.uvs) {
            var uvs = layer.uvs[name].uvs;
            var uvIndices = layer.uvs[name].uvIndices;
            uvIndices.forEach(function(i, j) {
                remappedUVs[i * 2] = uvs[j * 2];
                remappedUVs[i * 2 + 1] = uvs[j * 2 + 1];
            });
        }
        geometry.setAttribute("uv", new Float32BufferAttribute(remappedUVs, 2));
        #end
    }

    public function parseMorphTargets(geometry:Dynamic, layer:Dynamic):Void {
        #if js
        var num = 0;
        for (var name in layer.morphTargets) {
            var remappedPoints = geometry.attributes.position.array.slice();
            if (geometry.morphAttributes.position == null) geometry.morphAttributes.position = [];
            var morphPoints = layer.morphTargets[name].points;
            var morphIndices = layer.morphTargets[name].indices;
            var type = layer.morphTargets[name].type;
            morphIndices.forEach(function(i, j) {
                if (type == "relative") {
                    remappedPoints[i * 3] += morphPoints[j * 3];
                    remappedPoints[i * 3 + 1] += morphPoints[j * 3 + 1];
                    remappedPoints[i * 3 + 2] += morphPoints[j * 3 + 2];
                } else {
                    remappedPoints[i * 3] = morphPoints[j * 3];
                    remappedPoints[i * 3 + 1] = morphPoints[j * 3 + 1];
                    remappedPoints[i * 3 + 2] = morphPoints[j * 3 + 2];
                }
            });
            geometry.morphAttributes.position[num] = new Float32BufferAttribute(remappedPoints, 3);
            geometry.morphAttributes.position[num].name = name;
            num++;
        }
        geometry.morphTargetsRelative = false;
        #end
    }
}

function extractParentUrl(url:String, dir:String):String {
    #if js
    var index = url.indexOf(dir);
    if (index == -1) return "./";
    return url.slice(0, index);
    #end
}

#if js
class IFFParser {
    public function parse(iffBuffer:Bytes):Dynamic {
        var parser = new Parser(iffBuffer);
        return parser.parse();
    }
}

class Parser {
    public var buffer:Bytes;
    public var offset:Int;

    public function new(buffer:Bytes) {
        this.buffer = buffer;
        this.offset = 0;
    }

    public function parse():Dynamic {
        var chunk = this.readChunk();
        var chunks = [chunk];
        while (this.offset < this.buffer.length) {
            chunk = this.readChunk();
            chunks.push(chunk);
        }
        return chunks;
    }

    public function readChunk():Dynamic {
        var id = this.readString(4);
        var size = this.readInt();
        var formType = this.readString(4);
        var data = this.readString(size);
        return { id : id, size : size, formType : formType, data : data };
    }

    public function readString(length:Int):String {
        return this.buffer.getString(this.offset, length);
    }

    public function readInt():Int {
        var bytes = this.buffer.getInt32(this.offset);
        this.offset += 4;
        return bytes;
    }
}

class FileLoader {
    public function setPath(path:String):Void {}

    public function setResponseType(type:String):Void {}

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {}
}

class TextureLoader {
    public function setPath(path:String):Void {}

    public function setCrossOrigin(crossOrigin:String):Void {}

    public function load(path:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {}
}

class Mesh {
    public function add(mesh:Dynamic):Void {}

    public function traverse(callback:Dynamic):Void {}
}

class Points {
    public function new(geometry:Dynamic, materials:Dynamic) {}
}

class LineSegments {
    public function new(geometry:Dynamic, materials:Dynamic) {}
}

class BufferGeometry {
    public function setAttribute(name:String, attribute:Dynamic):Void {}

    public function setIndex(index:Dynamic):Void {}

    public function addGroup(start:Int, count:Int, materialIndex:Int):Void {}

    public function computeVertexNormals():Void {}

    public function translate(x:Float, y:Float, z:Float):Void {}
}

class Float32BufferAttribute {
    public function new(array:Array<Float>, itemSize:Int) {}
}

class PointsMaterial {
    public function new(parameters:Dynamic) {}
}

class LineBasicMaterial {
    public function new(parameters:Dynamic) {}
}

class MeshPhongMaterial {
    public function new(parameters:Dynamic) {}
}

class MeshPhysicalMaterial {
    public function new(parameters:Dynamic) {}
}

class MeshStandardMaterial {
    public function new(parameters:Dynamic) {}
}

class Color {
    public function new(value:Dynamic) {}

    public function fromArray(value:Array<Float>):Void {}

    public function multiplyScalar(scalar:Float):Void {}

    public function setScalar(scalar:Float):Void {}
}

class Vector2 {
    public function new(x:Float, y:Float) {}
}

class DoubleSide {

}

class BackSide {

}

class FrontSide {

}

class RepeatWrapping {

}

class MirroredRepeatWrapping {

}

class ClampToEdgeWrapping {

}

class SRGBColorSpace {

}

class EquirectangularReflectionMapping {

}

class EquirectangularRefractionMapping {

}

class AddOperation {

}

class Loader {
    public function new(manager:Dynamic) {}
}

class Window {
    public static function alert(message:String):Void {}
}
#end