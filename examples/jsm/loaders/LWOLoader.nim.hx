// File path: three/examples/jsm/loaders/LWOLoader.hx

import three.examples.jsm.loaders.lwo.IFFParser;
import three.examples.jsm.loaders.lwo.LWOTreeParser;
import three.examples.jsm.loaders.lwo.MaterialParser;
import three.examples.jsm.loaders.lwo.GeometryParser;
import three.examples.jsm.loaders.lwo.extractParentUrl;

class LWOLoader extends three.Loader {
    public var resourcePath(default, null):String;

    public function new(manager:three.LoadingManager, parameters:Dynamic) {
        super(manager);
        this.resourcePath = (parameters.resourcePath !== null) ? parameters.resourcePath : '';
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        var scope = this;
        var path = (scope.path === '') ? extractParentUrl(url, 'Objects') : scope.path;
        var modelName = url.split(path).pop().split('.')[0];
        var loader = new three.FileLoader(this.manager);
        loader.setPath(scope.path);
        loader.setResponseType('arraybuffer');
        loader.load(url, function(buffer) {
            try {
                onLoad(scope.parse(buffer, path, modelName));
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

    public function parse(iffBuffer:ArrayBuffer, path:String, modelName:String) {
        _lwoTree = new IFFParser().parse(iffBuffer);
        var textureLoader = new three.TextureLoader(this.manager).setPath(this.resourcePath || path).setCrossOrigin(this.crossOrigin);
        return new LWOTreeParser(textureLoader).parse(modelName);
    }
}

class LWOTreeParser {
    public var textureLoader:three.TextureLoader;

    public function new(textureLoader:three.TextureLoader) {
        this.textureLoader = textureLoader;
    }

    public function parse(modelName:String) {
        this.materials = new MaterialParser(this.textureLoader).parse();
        this.defaultLayerName = modelName;
        this.meshes = this.parseLayers();
        return {
            materials: this.materials,
            meshes: this.meshes,
        };
    }

    public function parseLayers() {
        var meshes = [];
        var finalMeshes = [];
        var geometryParser = new GeometryParser();
        var scope = this;
        _lwoTree.layers.forEach(function(layer) {
            var geometry = geometryParser.parse(layer.geometry, layer);
            var mesh = scope.parseMesh(geometry, layer);
            meshes[layer.number] = mesh;
            if (layer.parent === -1) finalMeshes.push(mesh);
            else meshes[layer.parent].add(mesh);
        });
        this.applyPivots(finalMeshes);
        return finalMeshes;
    }

    public function parseMesh(geometry:three.BufferGeometry, layer:Dynamic) {
        var mesh;
        var materials = this.getMaterials(geometry.userData.matNames, layer.geometry.type);
        if (layer.geometry.type === 'points') mesh = new three.Points(geometry, materials);
        else if (layer.geometry.type === 'lines') mesh = new three.LineSegments(geometry, materials);
        else mesh = new three.Mesh(geometry, materials);
        if (layer.name) mesh.name = layer.name;
        else mesh.name = this.defaultLayerName + '_layer_' + layer.number;
        mesh.userData.pivot = layer.pivot;
        return mesh;
    }

    public function applyPivots(meshes:Array<three.Object3D>) {
        meshes.forEach(function(mesh) {
            mesh.traverse(function(child) {
                var pivot = child.userData.pivot;
                child.position.x += pivot[0];
                child.position.y += pivot[1];
                child.position.z += pivot[2];
                if (child.parent) {
                    var parentPivot = child.parent.userData.pivot;
                    child.position.x -= parentPivot[0];
                    child.position.y -= parentPivot[1];
                    child.position.z -= parentPivot[2];
                }
            });
        });
    }

    public function getMaterials(namesArray:Array<String>, type:String) {
        var materials = [];
        var scope = this;
        namesArray.forEach(function(name, i) {
            materials[i] = scope.getMaterialByName(name);
        });
        if (type === 'points' || type === 'lines') {
            materials.forEach(function(mat, i) {
                var spec = {
                    color: mat.color,
                };
                if (type === 'points') {
                    spec.size = 0.1;
                    spec.map = mat.map;
                    materials[i] = new three.PointsMaterial(spec);
                } else if (type === 'lines') {
                    materials[i] = new three.LineBasicMaterial(spec);
                }
            });
        }
        var filtered = materials.filter(function(m) {
            return m !== null;
        });
        if (filtered.length === 1) return filtered[0];
        return materials;
    }

    public function getMaterialByName(name:String) {
        return this.materials.filter(function(m) {
            return m.name === name;
        })[0];
    }
}

class MaterialParser {
    public var textureLoader:three.TextureLoader;

    public function new(textureLoader:three.TextureLoader) {
        this.textureLoader = textureLoader;
    }

    public function parse() {
        var materials = [];
        this.textures = {};
        for (name in _lwoTree.materials) {
            if (_lwoTree.format === 'LWO3') {
                materials.push(this.parseMaterial(_lwoTree.materials[name], name, _lwoTree.textures));
            } else if (_lwoTree.format === 'LWO2') {
                materials.push(this.parseMaterialLwo2(_lwoTree.materials[name], name, _lwoTree.textures));
            }
        }
        return materials;
    }

    public function parseMaterial(materialData:Dynamic, name:String, textures:Dynamic) {
        var params = {
            name: name,
            side: this.getSide(materialData.attributes),
            flatShading: this.getSmooth(materialData.attributes),
        };
        var connections = this.parseConnections(materialData.connections, materialData.nodes);
        var maps = this.parseTextureNodes(connections.maps);
        this.parseAttributeImageMaps(connections.attributes, textures, maps, materialData.maps);
        var attributes = this.parseAttributes(connections.attributes, maps);
        this.parseEnvMap(connections, maps, attributes);
        params = Reflect.setField(maps, params);
        params = Reflect.setField(params, attributes);
        var materialType = this.getMaterialType(connections.attributes);
        if (materialType !== three.MeshPhongMaterial) delete params.refractionRatio;
        return new materialType(params);
    }

    public function parseMaterialLwo2(materialData:Dynamic, name:String/*, textures:Dynamic*/) {
        var params = {
            name: name,
            side: this.getSide(materialData.attributes),
            flatShading: this.getSmooth(materialData.attributes),
        };
        var attributes = this.parseAttributes(materialData.attributes, {});
        params = Reflect.setField(params, attributes);
        return new three.MeshPhongMaterial(params);
    }

    public function getSide(attributes:Dynamic) {
        if (!attributes.side) return three.BackSide;
        switch (attributes.side) {
            case 0:
            case 1:
                return three.BackSide;
            case 2: return three.FrontSide;
            case 3: return three.DoubleSide;
        }
    }

    public function getSmooth(attributes:Dynamic) {
        if (!attributes.smooth) return true;
        return !attributes.smooth;
    }

    public function parseConnections(connections:Dynamic, nodes:Dynamic) {
        var materialConnections = {
            maps: {}
        };
        var inputName = connections.inputName;
        var inputNodeName = connections.inputNodeName;
        var nodeName = connections.nodeName;
        var scope = this;
        inputName.forEach(function(name, index) {
            if (name === 'Material') {
                var matNode = scope.getNodeByRefName(inputNodeName[index], nodes);
                materialConnections.attributes = matNode.attributes;
                materialConnections.envMap = matNode.fileName;
                materialConnections.name = inputNodeName[index];
            }
        });
        nodeName.forEach(function(name, index) {
            if (name === materialConnections.name) {
                materialConnections.maps[inputName[index]] = scope.getNodeByRefName(inputNodeName[index], nodes);
            }
        });
        return materialConnections;
    }

    public function getNodeByRefName(refName:String, nodes:Dynamic) {
        for (name in nodes) {
            if (nodes[name].refName === refName) return nodes[name];
        }
    }

    public function parseTextureNodes(textureNodes:Dynamic) {
        var maps = {};
        for (name in textureNodes) {
            var node = textureNodes[name];
            var path = node.fileName;
            if (!path) return;
            var texture = this.loadTexture(path);
            if (node.widthWrappingMode !== undefined) texture.wrapS = this.getWrappingType(node.widthWrappingMode);
            if (node.heightWrappingMode !== undefined) texture.wrapT = this.getWrappingType(node.heightWrappingMode);
            switch (name) {
                case 'Color':
                    maps.map = texture;
                    maps.map.colorSpace = three.SRGBColorSpace;
                    break;
                case 'Roughness':
                    maps.roughnessMap = texture;
                    maps.roughness = 1;
                    break;
                case 'Specular':
                    maps.specularMap = texture;
                    maps.specularMap.colorSpace = three.SRGBColorSpace;
                    maps.specular = 0xffffff;
                    break;
                case 'Luminous':
                    maps.emissiveMap = texture;
                    maps.emissiveMap.colorSpace = three.SRGBColorSpace;
                    maps.emissive = 0x808080;
                    break;
                case 'Luminous Color':
                    maps.emissive = 0x808080;
                    break;
                case 'Metallic':
                    maps.metalnessMap = texture;
                    maps.metalness = 1;
                    break;
                case 'Transparency':
                case 'Alpha':
                    maps.alphaMap = texture;
                    maps.transparent = true;
                    break;
                case 'Normal':
                    maps.normalMap = texture;
                    if (node.amplitude !== undefined) maps.normalScale = new three.Vector2(node.amplitude, node.amplitude);
                    break;
                case 'Bump':
                    maps.bumpMap = texture;
                    break;
            }
        }
        if (maps.roughnessMap && maps.specularMap) delete maps.specularMap;
        return maps;
    }

    public function parseAttributeImageMaps(attributes:Dynamic, textures:Dynamic, maps:Dynamic) {
        for (name in attributes) {
            var attribute = attributes[name];
            if (attribute.maps) {
                var mapData = attribute.maps[0];
                var path = this.getTexturePathByIndex(mapData.imageIndex, textures);
                if (!path) return;
                var texture = this.loadTexture(path);
                if (mapData.wrap !== undefined) texture.wrapS = this.getWrappingType(mapData.wrap.w);
                if (mapData.wrap !== undefined) texture.wrapT = this.getWrappingType(mapData.wrap.h);
                switch (name) {
                    case 'Color':
                        maps.map = texture;
                        maps.map.colorSpace = three.SRGBColorSpace;
                        break;
                    case 'Diffuse':
                        maps.aoMap = texture;
                        break;
                    case 'Roughness':
                        maps.roughnessMap = texture;
                        maps.roughness = 1;
                        break;
                    case 'Specular':
                        maps.specularMap = texture;
                        maps.specularMap.colorSpace = three.SRGBColorSpace;
                        maps.specular = 0xffffff;
                        break;
                    case 'Luminosity':
                        maps.emissiveMap = texture;
                        maps.emissiveMap.colorSpace = three.SRGBColorSpace;
                        maps.emissive = 0x808080;
                        break;
                    case 'Metallic':
                        maps.metalnessMap = texture;
                        maps.metalness = 1;
                        break;
                    case 'Transparency':
                    case 'Alpha':
                        maps.alphaMap = texture;
                        maps.transparent = true;
                        break;
                    case 'Normal':
                        maps.normalMap = texture;
                        break;
                    case 'Bump':
                        maps.bumpMap = texture;
                        break;
                }
            }
        }
    }

    public function parseAttributes(attributes:Dynamic, maps:Dynamic) {
        var params = {};
        if (attributes.Color && !maps.map) {
            params.color = new three.Color().fromArray(attributes.Color.value);
        } else {
            params.color = new three.Color();
        }
        if (attributes.Transparency && attributes.Transparency.value !== 0) {
            params.opacity = 1 - attributes.Transparency.value;
            params.transparent = true;
        }
        if (attributes['Bump Height']) params.bumpScale = attributes['Bump Height'].value * 0.1;
        this.parsePhysicalAttributes(params, attributes, maps);
        this.parseStandardAttributes(params, attributes, maps);
        this.parsePhongAttributes(params, attributes, maps);
        return params;
    }

    public function parsePhysicalAttributes(params:Dynamic, attributes:Dynamic/*, maps:Dynamic*/) {
        if (attributes.Clearcoat && attributes.Clearcoat.value > 0) {
            params.clearcoat = attributes.Clearcoat.value;
            if (attributes['Clearcoat Gloss']) {
                params.clearcoatRoughness = 0.5 * (1 - attributes['Clearcoat Gloss'].value);
            }
        }
    }

    public function parseStandardAttributes(params:Dynamic, attributes:Dynamic, maps:Dynamic) {
        if (attributes.Luminous) {
            params.emissiveIntensity = attributes.Luminous.value;
            if (attributes['Luminous Color'] && !maps.emissive) {
                params.emissive = new three.Color().fromArray(attributes['Luminous Color'].value);
            } else {
                params.emissive = new three.Color(0x808080);
            }
        }
        if (attributes.Roughness && !maps.roughnessMap) params.roughness = attributes.Roughness.value;
        if (attributes.Metallic && !maps.metalnessMap) params.metalness = attributes.Metallic.value;
    }

    public function parsePhongAttributes(params:Dynamic, attributes:Dynamic, maps:Dynamic) {
        if (attributes['Refraction Index']) params.refractionRatio = 0.98 / attributes['Refraction Index'].value;
        if (attributes.Diffuse) params.color.multiplyScalar(attributes.Diffuse.value);
        if (attributes.Reflection) {
            params.reflectivity = attributes.Reflection.value;
            params.combine = three.AddOperation;
        }
        if (attributes.Luminosity) {
            params.emissiveIntensity = attributes.Luminosity.value;
            if (!maps.emissiveMap && !maps.map) {
                params.emissive = params.color;
            } else {
                params.emissive = new three.Color(0x808080);
            }
        }
        if (attributes.Specular && !maps.specularMap) {
            if (attributes['Color Highlight']) {
                params.specular = new three.Color().setScalar(attributes.Specular.value).lerp(params.color.clone().multiplyScalar(attributes.Specular.value), attributes['Color Highlight'].value);
            } else {
                params.specular = new three.Color().setScalar(attributes.Specular.value);
            }
        }
        if (params.specular && attributes.Glossiness) params.shininess = 7 + Math.pow(2, attributes.Glossiness.value * 12 + 2);
    }

    public function parseEnvMap(connections:Dynamic, maps:Dynamic, attributes:Dynamic) {
        if (connections.envMap) {
            var envMap = this.loadTexture(connections.envMap);
            if (attributes.transparent && attributes.opacity < 0.999) {
                envMap.mapping = three.EquirectangularRefractionMapping;
                if (attributes.reflectivity !== undefined) {
                    delete attributes.reflectivity;
                    delete attributes.combine;
                }
                if (attributes.metalness !== undefined) {
                    attributes.metalness = 1;
                }
                attributes.opacity = 1;
            } else envMap.mapping = three.EquirectangularReflectionMapping;
            maps.envMap = envMap;
        }
    }

    public function getTexturePathByIndex(index:Int, textures:Dynamic) {
        var fileName = '';
        if (!_lwoTree.textures) return fileName;
        _lwoTree.textures.forEach(function(texture) {
            if (texture.index === index) fileName = texture.fileName;
        });
        return fileName;
    }

    public function loadTexture(path:String) {
        if (!path) return null;
        var texture = this.textureLoader.load(path, undefined, undefined, function() {
            trace('LWOLoader: non-standard resource hierarchy. Use `resourcePath` parameter to specify root content directory.');
        });
        return texture;
    }

    public function getWrappingType(num:Int) {
        switch (num) {
            case 0:
                trace('LWOLoader: "Reset" texture wrapping type is not supported in three.js');
                return three.ClampToEdgeWrapping;
            case 1: return three.RepeatWrapping;
            case 2: return three.MirroredRepeatWrapping;
            case 3: return three.ClampToEdgeWrapping;
        }
    }

    public function getMaterialType(nodeData:Dynamic) {
        if (nodeData.Clearcoat && nodeData.Clearcoat.value > 0) return three.MeshPhysicalMaterial;
        if (nodeData.Roughness) return three.MeshStandardMaterial;
        return three.MeshPhongMaterial;
    }
}

class GeometryParser {
    public function parse(geoData:Dynamic, layer:Dynamic) {
        var geometry = new three.BufferGeometry();
        geometry.setAttribute('position', new three.Float32BufferAttribute(geoData.points, 3));
        var indices = this.splitIndices(geoData.vertexIndices, geoData.polygonDimensions);
        geometry.setIndex(indices);
        this.parseGroups(geometry, geoData);
        geometry.computeVertexNormals();
        this.parseUVs(geometry, layer, indices);
        this.parseMorphTargets(geometry, layer, indices);
        geometry.translate(-layer.pivot[0], -layer.pivot[1], -layer.pivot[2]);
        return geometry;
    }

    public function splitIndices(indices:Array<Int>, polygonDimensions:Array<Int>) {
        var remappedIndices = [];
        var i = 0;
        polygonDimensions.forEach(function(dim) {
            if (dim < 4) {
                for (k in 0...dim) remappedIndices.push(indices[i + k]);
            } else if (dim === 4) {
                remappedIndices.push(indices[i], indices[i + 1], indices[i + 2], indices[i], indices[i + 2], indices[i + 3]);
            } else if (dim > 4) {
                for (k in 1...dim - 1) {
                    remappedIndices.push(indices[i], indices[i + k], indices[i + k + 1]);
                }
                trace('LWOLoader: polygons with greater than 4 sides are not supported');
            }
            i += dim;
        });
        return remappedIndices;
    }

    public function parseGroups(geometry:three.BufferGeometry, geoData:Dynamic) {
        var tags = _lwoTree.tags;
        var matNames = [];
        var elemSize = 3;
        if (geoData.type === 'lines') elemSize = 2;
        if (geoData.type === 'points') elemSize = 1;
        var remappedIndices = this.splitMaterialIndices(geoData.polygonDimensions, geoData.materialIndices);
        var indexNum = 0;
        var indexPairs = {};
        var prevMaterialIndex;
        var materialIndex;
        var prevStart = 0;
        var currentCount = 0;
        for (i in 0...remappedIndices.length) {
            materialIndex = remappedIndices[i + 1];
            if (i === 0) matNames[indexNum] = tags[materialIndex];
            if (prevMaterialIndex === null) prevMaterialIndex = materialIndex;
            if (materialIndex !== prevMaterialIndex) {
                var currentIndex;
                if (indexPairs[tags[prevMaterialIndex]] !== null) {
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
            if (indexPairs[tags[materialIndex]] !== null) {
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

    public function splitMaterialIndices(polygonDimensions:Array<Int>, indices:Array<Int>) {
        var remappedIndices = [];
        polygonDimensions.forEach(function(dim, i) {
            if (dim <= 3) {
                remappedIndices.push(indices[i * 2], indices[i * 2 + 1]);
            } else if (dim === 4) {
                remappedIndices.push(indices[i * 2], indices[i * 2 + 1], indices[i * 2], indices[i * 2 + 1]);
            } else {
                for (k in 0...dim - 2) {
                    remappedIndices.push(indices[i * 2], indices[i * 2 + 1]);
                }
            }
        });
        return remappedIndices;
    }

    public function parseUVs(geometry:three.BufferGeometry, layer:Dynamic, indices:Array<Int>) {
        var remappedUVs = Array.from(Array(geometry.attributes.position.count * 2), function() {
            return 0;
        });
        for (name in layer.uvs) {
            var uvs = layer.uvs[name].uvs;
            var uvIndices = layer.uvs[name].uvIndices;
            uvIndices.forEach(function(i, j) {
                remappedUVs[i * 2] = uvs[j * 2];
                remappedUVs[i * 2 + 1] = uvs[j * 2 + 1];
            });
        }
        geometry.setAttribute('uv', new three.Float32BufferAttribute(remappedUVs, 2));
    }

    public function parseMorphTargets(geometry:three.BufferGeometry, layer:Dynamic, indices:Array<Int>) {
        var num = 0;
        for (name in layer.morphTargets) {
            var remappedPoints = geometry.attributes.position.array.slice();
            if (!geometry.morphAttributes.position) geometry.morphAttributes.position = [];
            var morphPoints = layer.morphTargets[name].points;
            var morphIndices = layer.morphTargets[name].indices;
            var type = layer.morphTargets[name].type;
            morphIndices.forEach(function(i, j) {
                if (type === 'relative') {
                    remappedPoints[i * 3] += morphPoints[j * 3];
                    remappedPoints[i * 3 + 1] += morphPoints[j * 3 + 1];
                    remappedPoints[i * 3 + 2] += morphPoints[j * 3 + 2];
                } else {
                    remappedPoints[i * 3] = morphPoints[j * 3];
                    remappedPoints[i * 3 + 1] = morphPoints[j * 3 + 1];
                    remappedPoints[i * 3 + 2] = morphPoints[j * 3 + 2];
                }
            });
            geometry.morphAttributes.position[num] = new three.Float32BufferAttribute(remappedPoints, 3);
            geometry.morphAttributes.position[num].name = name;
            num++;
        }
        geometry.morphTargetsRelative = false;
    }
}

// ************** UTILITY FUNCTIONS **************

function extractParentUrl(url:String, dir:String) {
    var index = url.indexOf(dir);
    if (index === -1) return './';
    return url.slice(0, index);
}

export { LWOLoader };