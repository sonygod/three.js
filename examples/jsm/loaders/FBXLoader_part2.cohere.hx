class FBXTreeParser {
    private var textureLoader:TextureLoader;
    private var manager:Manager;

    public function new(textureLoader:TextureLoader, manager:Manager) {
        this.textureLoader = textureLoader;
        this.manager = manager;
    }

    public function parse():Scene {
        var connections = parseConnections();

        var images = parseImages();
        var textures = parseTextures(images);
        var materials = parseMaterials(textures);
        var deformers = parseDeformers();
        var geometryMap = new GeometryParser().parse(deformers);

        parseScene(deformers, geometryMap, materials);

        return sceneGraph;
    }

    private function parseConnections():ConnectionMap {
        var connectionMap = new Map();

        if (fbxTree.hasOwnProperty('Connections')) {
            var rawConnections = fbxTree.Connections.connections;

            for (rawConnection in rawConnections) {
                var fromID = rawConnection[0];
                var toID = rawConnection[1];
                var relationship = rawConnection[2];

                if (!connectionMap.exists(fromID)) {
                    connectionMap.set(fromID, {parents: [], children: []});
                }

                var parentRelationship = {ID: toID, relationship: relationship};
                connectionMap.get(fromID).parents.push(parentRelationship);

                if (!connectionMap.exists(toID)) {
                    connectionMap.set(toID, {parents: [], children: []});
                }

                var childRelationship = {ID: fromID, relationship: relationship};
                connectionMap.get(toID).children.push(childRelationship);
            }
        }

        return connectionMap;
    }

    private function parseImages():Map<Int, String> {
        var images = new Map<Int, String>();
        var blobs = new Map<String, BlobData>();

        if (fbxTree.Objects.hasOwnProperty('Video')) {
            var videoNodes = fbxTree.Objects.Video;

            for (nodeID in videoNodes) {
                var videoNode = videoNodes[Std.parseInt(nodeID)];

                var id = Std.parseInt(nodeID);

                images.set(id, videoNode.RelativeFilename ?? videoNode.Filename);

                if (videoNode.hasOwnProperty('Content')) {
                    var arrayBufferContent = (videoNode.Content instanceof ArrayBuffer) && (videoNode.Content.byteLength > 0);
                    var base64Content = (Std.isString(videoNode.Content) && (videoNode.Content != ''));

                    if (arrayBufferContent || base64Content) {
                        var image = parseImage(videoNodes[nodeID]);

                        blobs.set(videoNode.RelativeFilename ?? videoNode.Filename, image);
                    }
                }
            }
        }

        for (id in images) {
            var filename = images.get(id);

            if (blobs.exists(filename)) images.set(id, blobs.get(filename));
            else images.set(id, images.get(id).split('\\').pop());
        }

        return images;
    }

    private function parseImage(videoNode):BlobData {
        var content = videoNode.Content;
        var fileName = videoNode.RelativeFilename ?? videoNode.Filename;
        var extension = fileName.substring(fileName.lastIndexOf('.') + 1, fileName.length).toLowerCase();

        var type:String;

        switch (extension) {
            case 'bmp':
                type = 'image/bmp';
                break;
            case 'jpg':
            case 'jpeg':
                type = 'image/jpeg';
                break;
            case 'png':
                type = 'image/png';
                break;
            case 'tif':
                type = 'image/tiff';
                break;
            case 'tga':
                if (manager.getHandler('.tga') == null) {
                    trace('FBXLoader: TGA loader not found, skipping ' + fileName);
                }
                type = 'image/tga';
                break;
            default:
                trace('FBXLoader: Image type "' + extension + '" is not supported.');
                return null;
        }

        if (Std.isString(content)) { // ASCII format
            return 'data:' + type + ';base64,' + content;
        } else { // Binary Format
            var array = new Uint8Array(content);
            return window.URL.createObjectURL(new Blob([array], {type: type}));
        }
    }

    private function parseTextures(images:Map<Int, String>):TextureMap {
        var textureMap = new Map();

        if (fbxTree.Objects.hasOwnProperty('Texture')) {
            var textureNodes = fbxTree.Objects.Texture;
            for (nodeID in textureNodes) {
                var texture = parseTexture(textureNodes[nodeID], images);
                textureMap.set(Std.parseInt(nodeID), texture);
            }
        }

        return textureMap;
    }

    private function parseTexture(textureNode, images):Texture {
        var texture = loadTexture(textureNode, images);

        texture.ID = textureNode.id;
        texture.name = textureNode.attrName;

        var wrapModeU = textureNode.WrapModeU;
        var wrapModeV = textureNode.WrapModeV;

        var valueU = wrapModeU != null ? wrapModeU.value : 0;
        var valueV = wrapModeV != null ? wrapModeV.value : 0;

        // http://download.autodesk.com/us/fbx/SDKdocs/FBX_SDK_Help/files/fbxsdkref/class_k_fbx_texture.html#889640e63e2e681259ea81061b85143a
        // 0: repeat(default), 1: clamp

        texture.wrapS = valueU == 0 ? RepeatWrapping : ClampToEdgeWrapping;
        texture.wrapT = valueV == 0 ? RepeatWrapping : ClampToEdgeWrapping;

        if (textureNode.hasOwnProperty('Scaling')) {
            var values = textureNode.Scaling.value;

            texture.repeat.x = values[0];
            texture.repeat.y = values[1];
        }

        if (textureNode.hasOwnProperty('Translation')) {
            var values = textureNode.Translation.value;

            texture.offset.x = values[0];
            texture.offset.y = values[1];
        }

        return texture;
    }

    private function loadTexture(textureNode, images):Texture {
        var fileName:String;

        var currentPath = textureLoader.path;

        var children = connections.get(textureNode.id).children;

        if (children != null && children.length > 0 && images.exists(children[0].ID)) {
            fileName = images.get(children[0].ID);

            if (fileName.indexOf('blob:') == 0 || fileName.indexOf('data:') == 0) {
                textureLoader.setPath(null);
            }
        }

        var texture:Texture;

        var extension = textureNode.FileName.substring(textureNode.FileName.length - 3, textureNode.FileName.length).toLowerCase();

        if (extension == 'tga') {
            var loader = manager.getHandler('.tga');

            if (loader == null) {
                trace('FBXLoader: TGA loader not found, creating placeholder texture for ' + textureNode.RelativeFilename);
                texture = new Texture();
            } else {
                loader.setPath(textureLoader.path);
                texture = loader.load(fileName);
            }
        } else if (extension == 'dds') {
            var loader = manager.getHandler('.dds');

            if (loader == null) {
                trace('FBXLoader: DDS loader not found, creating placeholder texture for ' + textureNode.RelativeFilename);
                texture = new Texture();
            } else {
                loader.setPath(textureLoader.path);
                texture = loader.load(fileName);
            }
        } else if (extension == 'psd') {
            trace('FBXLoader: PSD textures are not supported, creating placeholder texture for ' + textureNode.RelativeFilename);
            texture = new Texture();
        } else {
            texture = textureLoader.load(fileName);
        }

        textureLoader.setPath(currentPath);

        return texture;
    }

    private function parseMaterials(textureMap):MaterialMap {
        var materialMap = new Map();

        if (fbxTree.Objects.hasOwnProperty('Material')) {
            var materialNodes = fbxTree.Objects.Material;

            for (nodeID in materialNodes) {
                var material = parseMaterial(materialNodes[nodeID], textureMap);

                if (material != null) materialMap.set(Std.parseInt(nodeID), material);
            }
        }

        return materialMap;
    }

    private function parseMaterial(materialNode, textureMap, ID:Int):Material {
        var name = materialNode.attrName;
        var type = materialNode.ShadingModel;

        // Case where FBX wraps shading model in property object.
        if (type is Object) {
            type = type.value;
        }

        // Ignore unused materials which don't have any connections.
        if (!connections.exists(ID)) return null;

        var parameters = parseParameters(materialNode, textureMap, ID);

        var material:Material;

        switch (type.toLowerCase()) {
            case 'phong':
                material = new MeshPhongMaterial();
                break;
            case 'lambert':
                material = new MeshLambertMaterial();
                break;
            default:
                trace('THREE.FBXLoader: unknown material type "' + type + '". Defaulting to MeshPhongMaterial.');
                material = new MeshPhongMaterial();
                break;
        }

        material.setValues(parameters);
        material.name = name;

        return material;
    }

    private function parseParameters(materialNode, textureMap, ID:Int):Map<String, dynamic> {
        var parameters = new Map();

        if (materialNode.hasOwnProperty('BumpFactor')) {
            parameters.set('bumpScale', materialNode.BumpFactor.value);
        }

        if (materialNode.hasOwnProperty('Diffuse')) {
            parameters.set('color', new Color().fromArray(materialNode.Diffuse.value).convertSRGBToLinear());
        } else if (materialNode.hasOwnProperty('DiffuseColor') && (materialNode.DiffuseColor.type == 'Color' || materialNode.DiffuseColor.type == 'ColorRGB')) {
            // The blender exporter exports diffuse here instead of in materialNode.Diffuse
            parameters.set('color', new Color().fromArray(materialNode.DiffuseColor.value).convertSRGBToLinear());
        }

        if (materialNode.hasOwnProperty('DisplacementFactor')) {
            parameters.set('displacementScale', materialNode.DisplacementFactor.value);
        }

        if (materialNode.hasOwnProperty('Emissive')) {
            parameters.set('emissive', new Color().fromArray(materialNode.Emissive.value).convertSRGBToLinear());
        } else if (materialNode.hasOwnProperty('EmissiveColor') && (materialNode.EmissiveColor.type == 'Color' || materialNode.EmissiveColor.type == 'ColorRGB')) {
            // The blender exporter exports emissive color here instead of in materialNode.Emissive
            parameters.set('emissive', new Color().fromArray(materialNode.EmissiveColor.value).convertSRGBToLinear());
        }

        if (materialNode.hasOwnProperty('EmissiveFactor')) {
            parameters.set('emissiveIntensity', Std.parseFloat(materialNode.EmissiveFactor.value));
        }

        if (materialNode.hasOwnProperty('Opacity')) {
            parameters.set('opacity', Std.parseFloat(materialNode.Opacity.value));
        }

        if (parameters.get('opacity') < 1.0) {
            parameters.set('transparent', true);
        }

        if (materialNode.hasOwnProperty('ReflectionFactor')) {
            parameters.set('reflectivity', materialNode.ReflectionFactor.value);
        }

        if (materialNode.hasOwnProperty('Shininess')) {
            parameters.set('shininess', materialNode.Shininess.value);
        }

        if (materialNode.hasOwnProperty('Specular')) {
            parameters.set('specular', new Color().fromArray(materialNode.Specular.value).convertSRGBToLinear());
        } else if (materialNode.hasOwnProperty('SpecularColor') && materialNode.SpecularColor.type == 'Color') {
            // The blender exporter exports specular color here instead of in materialNode.Specular
            parameters.set('specular', new Color().fromArray(materialNode.SpecularColor.value).convertSRGBToLinear());
        }

        connections.get(ID).children.forEach(function (child) {
            var type = child.relationship;

            switch (type) {
                case 'Bump':
                    parameters.set('bumpMap', getTexture(textureMap, child.ID));
                    break;
                case 'Maya|TEX_ao_map':
                    parameters.set('aoMap', getTexture(textureMap, child.ID));
                    break;
                case 'DiffuseColor':
                case 'Maya|TEX_color_map':
                    parameters.set('map', getTexture(textureMap, child.ID));
                    if (parameters.get('map') != null) {
                        parameters.get('map').colorSpace = SRGBColorSpace;
                    }
                    break;
                case 'DisplacementColor':
                    parameters.set('displacementMap', getTexture(textureMap, child.ID));
                    break;
                case 'EmissiveColor':
                    parameters.set('emissiveMap', getTexture(textureMap, child.ID));
                    if (parameters.get('emissiveMap') != null) {
                        parameters.get('emissiveMap').colorSpace = SRGBColorSpace;
                    }
                    break;
                case 'NormalMap':
                case 'Maya|TEX_normal_map':
                    parameters.set('normalMap', getTexture(textureMap, child.ID));
                    break;
                case 'ReflectionColor':
                    parameters.set('envMap', getTexture(textureMap, child.ID));
                    if (parameters.get('envMap') != null) {
                        parameters.get('envMap').mapping = EquirectangularReflectionMapping;
                        parameters.get('envMap').colorSpace = SRGBColorSpace;
                    }
                    break;
                case 'SpecularColor':
                    parameters.set('specularMap', getTexture(textureMap, child.ID));
                    if (parameters.get('specularMap') != null) {
                        parameters.get('specularMap').colorSpace = SRGBColorSpace;
                    }
                    break;
                case 'TransparentColor':
                case 'TransparencyFactor':
                    parameters.set('alphaMap', getTexture(textureMap, child.ID));
                    parameters.set('transparent', true);
                    break;
                case 'AmbientColor':
                case 'ShininessExponent': // AKA glossiness map
                case 'SpecularFactor': // AKA specularLevel
                case 'VectorDisplacementColor': // NOTE: Seems to be a copy of DisplacementColor
                default:
                    trace('THREE.FBXLoader: ' + type + ' map is not supported in three.js, skipping texture.');
                    break;
            }
        });

        return parameters;
    }

    private function getTexture(textureMap, id):Texture {
        // if the texture is a layered texture, just use the first layer and issue a warning
        if (fbxTree.Objects.hasOwnProperty('LayeredTexture') && fbxTree.Objects.LayeredTexture.hasOwnProperty(id)) {
            trace('THREE.FBXLoader: layered textures are not supported in three.js. Discarding all but first layer.');
            id = connections.get(id).children[0].ID;
        }

        return textureMap.get(id);
    }

    private function parseDeformers():DeformerMap {
        var skeletons = new Map<Int, Skeleton>();
        var morphTargets = new Map<Int, MorphTarget>();

        if (fbxTree.Objects.hasOwnProperty('Deformer')) {
            var DeformerNodes = fbxTree.Objects.Deformer;

            for (nodeID in DeformerNodes) {
                var deformerNode = DeformerNodes[Std.parseInt(nodeID)];

                var relationships = connections.get(Std.parseInt(nodeID));

                if (deformerNode.attrType == 'Skin') {
                    var skeleton = parseSkeleton(relationships, DeformerNodes);
                    skeleton.ID = nodeID;

                    if (relationships.parents.length > 1) trace('THREE.FBXLoader: skeleton attached to more than one geometry is not supported.');
                    skeleton.geometryID = relationships.parents[0].ID;

                    skeletons.set(nodeID, skeleton);
                } else if (deformerNode.attrType == 'BlendShape') {
                    var morphTarget = {id: nodeID};

                    morphTarget.rawTargets = parseMorphTargets(relationships, DeformerNodes);
                    morphTarget.id = nodeID;

                    if (relationships.parents.length > 1) trace('THREE.FBXLoader: morph target attached to more than one geometry is not supported.');

                    morphTargets.set(nodeID, morphTarget);
                }
            }
        }

        return {skeletons: skeletons, morphTargets: morphTargets};
    }

    private function parseSkeleton(relationships, deformerNodes):Skeleton {
        var rawBones = [];

        relationships.children.forEach(function (child) {
            var boneNode = deformerNodes[child.ID];

            if (boneNode.attrType != 'Cluster') return;

            var rawBone = {
                ID: child.ID,
                indices: [],
                weights: [],
                transformLink: new Matrix4().fromArray(boneNode.TransformLink.a),
                // transform: new Matrix4().fromArray(boneNode.Transform.a),
                // linkMode: boneNode.Mode,
            };

            if (boneNode.hasOwnProperty('Indexes')) {
                rawBone.indices = boneNode.Indexes.a;
                rawBone.weights = boneNode.Weights.a;
            }

            rawBones.push(rawBone);
        });

        return {rawBones: rawBones, bones: []};
    }

    private function parseMorphTargets(relationships, deformerNodes):Array<MorphTarget> {
        var rawMorphTargets = [];

        for (i in 0...relationships.children.length) {
            var child =