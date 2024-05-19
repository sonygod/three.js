package three.js.examples.jm.loaders;

import three.js.loaders.LWOLoader;
import three.js.textures.TextureLoader;

class MaterialParser {

    private var textureLoader:TextureLoader;

    public function new(textureLoader:TextureLoader) {
        this.textureLoader = textureLoader;
    }

    public function parse():Array<Material> {
        var materials:Array<Material> = [];
        var textures:Dynamic = {};

        for (name in _lwoTree.materials) {
            if (_lwoTree.format == 'LWO3') {
                materials.push(parseMaterial(_lwoTree.materials[name], name, _lwoTree.textures));
            } else if (_lwoTree.format == 'LWO2') {
                materials.push(parseMaterialLwo2(_lwoTree.materials[name], name/*, _lwoTree.textures*/));
            }
        }

        return materials;
    }

    private function parseMaterial(materialData:Dynamic, name:String, textures:Dynamic):Material {
        var params:Dynamic = {
            name: name,
            side: getSide(materialData.attributes),
            flatShading: getSmooth(materialData.attributes)
        };

        var connections:Dynamic = parseConnections(materialData.connections, materialData.nodes);
        var maps:Dynamic = parseTextureNodes(connections.maps);

        parseAttributeImageMaps(connections.attributes, textures, maps, materialData.maps);

        var attributes:Dynamic = parseAttributes(connections.attributes, maps);

        parseEnvMap(connections, maps, attributes);

        params = Object.assign(maps, params);
        params = Object.assign(params, attributes);

        var materialType:Class<Material> = getMaterialType(connections.attributes);

        if (materialType != MeshPhongMaterial) Reflect.deleteField(params, 'refractionRatio'); // PBR materials do not support "refractionRatio"

        return Type.createInstance(materialType, [params]);
    }

    private function parseMaterialLwo2(materialData:Dynamic, name:String/*, textures:Dynamic*/):Material {
        var params:Dynamic = {
            name: name,
            side: getSide(materialData.attributes),
            flatShading: getSmooth(materialData.attributes)
        };

        var attributes:Dynamic = parseAttributes(materialData.attributes, {});
        params = Object.assign(params, attributes);
        return Type.createInstance(MeshPhongMaterial, [params]);
    }

    // Note: converting from left to right handed coords by switching x -> -x in vertices, and
    // then switching mat FrontSide -> BackSide
    // NB: this means that FrontSide and BackSide have been switched!
    private function getSide(attributes:Dynamic):Int {
        if (!attributes.side) return BackSide;

        switch (attributes.side) {
            case 0:
            case 1:
                return BackSide;
            case 2:
                return FrontSide;
            case 3:
                return DoubleSide;
        }

        return BackSide;
    }

    private function getSmooth(attributes:Dynamic):Bool {
        if (!attributes.smooth) return true;
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
        inputName.forEach(function (name:String, index:Int) {
            if (name == 'Material') {
                var matNode:Dynamic = getNodeByRefName(inputNodeName[index], nodes);
                materialConnections.attributes = matNode.attributes;
                materialConnections.envMap = matNode.fileName;
                materialConnections.name = inputNodeName[index];
            }
        });

        nodeName.forEach(function (name:String, index:Int) {
            if (name == materialConnections.name) {
                materialConnections.maps[inputName[index]] = getNodeByRefName(inputNodeName[index], nodes);
            }
        });

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

            if (path == null) return;

            var texture:Texture = loadTexture(path);

            if (node.widthWrappingMode != null) texture.wrapS = getWrappingType(node.widthWrappingMode);
            if (node.heightWrappingMode != null) texture.wrapT = getWrappingType(node.heightWrappingMode);

            switch (name) {
                case 'Color':
                    maps.map = texture;
                    maps.map.colorSpace = SRGBColorSpace;
                    break;
                case 'Roughness':
                    maps.roughnessMap = texture;
                    maps.roughness = 1;
                    break;
                case 'Specular':
                    maps.specularMap = texture;
                    maps.specularMap.colorSpace = SRGBColorSpace;
                    maps.specular = 0xffffff;
                    break;
                case 'Luminous':
                    maps.emissiveMap = texture;
                    maps.emissiveMap.colorSpace = SRGBColorSpace;
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
                    if (node.amplitude != null) maps.normalScale = new Vector2(node.amplitude, node.amplitude);
                    break;
                case 'Bump':
                    maps.bumpMap = texture;
                    break;
            }
        }

        // LWO BSDF materials can have both spec and rough, but this is not valid in three
        if (maps.roughnessMap && maps.specularMap) Reflect.deleteField(maps, 'specularMap');

        return maps;
    }

    // maps can also be defined on individual material attributes, parse those here
    // This occurs on Standard (Phong) surfaces
    private function parseAttributeImageMaps(attributes:Dynamic, textures:Dynamic, maps:Dynamic) {
        for (name in attributes) {
            var attribute:Dynamic = attributes[name];

            if (attribute.maps) {
                var mapData:Dynamic = attribute.maps[0];

                var path:String = getTexturePathByIndex(mapData.imageIndex, textures);
                if (path == null) return;

                var texture:Texture = loadTexture(path);

                if (mapData.wrap != null) texture.wrapS = getWrappingType(mapData.wrap.w);
                if (mapData.wrap != null) texture.wrapT = getWrappingType(mapData.wrap.h);

                switch (name) {
                    case 'Color':
                        maps.map = texture;
                        maps.map.colorSpace = SRGBColorSpace;
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
                        maps.specularMap.colorSpace = SRGBColorSpace;
                        maps.specular = 0xffffff;
                        break;
                    case 'Luminosity':
                        maps.emissiveMap = texture;
                        maps.emissiveMap.colorSpace = SRGBColorSpace;
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

    private function parseAttributes(attributes:Dynamic, maps:Dynamic):Dynamic {
        var params:Dynamic = {};

        // don't use color data if color map is present
        if (attributes.Color && maps.map == null) {
            params.color = new Color().fromArray(attributes.Color.value);
        } else {
            params.color = new Color();
        }

        if (attributes.Transparency && attributes.Transparency.value != 0) {
            params.opacity = 1 - attributes.Transparency.value;
            params.transparent = true;
        }

        if (attributes['Bump Height']) params.bumpScale = attributes['Bump Height'].value * 0.1;

        parsePhysicalAttributes(params, attributes, maps);
        parseStandardAttributes(params, attributes, maps);
        parsePhongAttributes(params, attributes, maps);

        return params;
    }

    private function parsePhysicalAttributes(params:Dynamic, attributes:Dynamic, maps:Dynamic) {
        if (attributes.Clearcoat && attributes.Clearcoat.value > 0) {
            params.clearcoat = attributes.Clearcoat.value;

            if (attributes['Clearcoat Gloss']) {
                params.clearcoatRoughness = 0.5 * (1 - attributes['Clearcoat Gloss'].value);
            }
        }
    }

    private function parseStandardAttributes(params:Dynamic, attributes:Dynamic, maps:Dynamic) {
        if (attributes.Luminous) {
            params.emissiveIntensity = attributes.Luminous.value;

            if (attributes['Luminous Color'] && !maps.emissive) {
                params.emissive = new Color().fromArray(attributes['Luminous Color'].value);
            } else {
                params.emissive = new Color(0x808080);
            }
        }

        if (attributes.Roughness && !maps.roughnessMap) params.roughness = attributes.Roughness.value;
        if (attributes.Metallic && !maps.metalnessMap) params.metalness = attributes.Metallic.value;
    }

    private function parsePhongAttributes(params:Dynamic, attributes:Dynamic, maps:Dynamic) {
        if (attributes['Refraction Index']) params.refractionRatio = 0.98 / attributes['Refraction Index'].value;

        if (attributes.Diffuse) params.color.multiplyScalar(attributes.Diffuse.value);

        if (attributes.Reflection) {
            params.reflectivity = attributes.Reflection.value;
            params.combine = AddOperation;
        }

        if (attributes.Luminosity) {
            params.emissiveIntensity = attributes.Luminosity.value;

            if (!maps.emissiveMap && !maps.map) {
                params.emissive = params.color;
            } else {
                params.emissive = new Color(0x808080);
            }
        }

        // parse specular if there is no roughness - we will interpret the material as 'Phong' in this case
        if (!attributes.Roughness && attributes.Specular && !maps.specularMap) {
            if (attributes['Color Highlight']) {
                params.specular = new Color().setScalar(attributes.Specular.value).lerp(params.color.clone().multiplyScalar(attributes.Specular.value), attributes['Color Highlight'].value);
            } else {
                params.specular = new Color().setScalar(attributes.Specular.value);
            }
        }

        if (params.specular && attributes.Glossiness) params.shininess = 7 + Math.pow(2, attributes.Glossiness.value * 12 + 2);
    }

    private function parseEnvMap(connections:Dynamic, maps:Dynamic, attributes:Dynamic) {
        if (connections.envMap) {
            var envMap:Texture = loadTexture(connections.envMap);

            if (attributes.transparent && attributes.opacity < 0.999) {
                envMap.mapping = EquirectangularRefractionMapping;

                // Reflectivity and refraction mapping don't work well together in Phong materials
                if (attributes.reflectivity != null) {
                    Reflect.deleteField(attributes, 'reflectivity');
                    Reflect.deleteField(attributes, 'combine');
                }

                if (attributes.metalness != null) {
                    attributes.metalness = 1; // For most transparent materials metalness should be set to 1 if not otherwise defined. If set to 0 no refraction will be visible
                }

                attributes.opacity = 1; // transparency fades out refraction, forcing opacity to 1 ensures a closer visual match to the material in Lightwave.
            } else {
                envMap.mapping = EquirectangularReflectionMapping;
            }

            maps.envMap = envMap;
        }
    }

    // get texture defined at top level by its index
    private function getTexturePathByIndex(index:Int):String {
        var fileName:String = '';

        if (!_lwoTree.textures) return fileName;

        _lwoTree.textures.forEach(function (texture:Dynamic) {
            if (texture.index == index) fileName = texture.fileName;
        });

        return fileName;
    }

    private function loadTexture(path:String):Texture {
        if (path == null) return null;

        var texture:Texture = textureLoader.load(path, null, null, function () {
            Console.warn('LWOLoader: non-standard resource hierarchy. Use `resourcePath` parameter to specify root content directory.');
        });

        return texture;
    }

    // 0 = Reset, 1 = Repeat, 2 = Mirror, 3 = Edge
    private function getWrappingType(num:Int):Int {
        switch (num) {
            case 0:
                Console.warn('LWOLoader: "Reset" texture wrapping type is not supported in three.js');
                return ClampToEdgeWrapping;
            case 1:
                return RepeatWrapping;
            case 2:
                return MirroredRepeatWrapping;
            case 3:
                return ClampToEdgeWrapping;
        }

        return ClampToEdgeWrapping;
    }

    private function getMaterialType(nodeData:Dynamic):Class<Material> {
        if (nodeData.Clearcoat && nodeData.Clearcoat.value > 0) return MeshPhysicalMaterial;
        if (nodeData.Roughness) return MeshStandardMaterial;
        return MeshPhongMaterial;
    }
}