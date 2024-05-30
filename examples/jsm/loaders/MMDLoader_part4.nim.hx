import three.js.examples.jsm.loaders.MMDLoader;
import three.js.examples.jsm.loaders.TGALoader;
import three.js.examples.jsm.loaders.TextureLoader;
import three.js.examples.jsm.loaders.MMDToonMaterial;
import three.js.examples.jsm.loaders.DEFAULT_TOON_TEXTURES;
import three.js.examples.jsm.loaders.NON_ALPHA_CHANNEL_FORMATS;
import three.js.examples.jsm.loaders.Color;
import three.js.examples.jsm.loaders.SRGBColorSpace;
import three.js.examples.jsm.loaders.CustomBlending;
import three.js.examples.jsm.loaders.SrcAlphaFactor;
import three.js.examples.jsm.loaders.OneMinusSrcAlphaFactor;
import three.js.examples.jsm.loaders.DstAlphaFactor;
import three.js.examples.jsm.loaders.DoubleSide;
import three.js.examples.jsm.loaders.FrontSide;
import three.js.examples.jsm.loaders.MultiplyOperation;
import three.js.examples.jsm.loaders.AddOperation;
import three.js.examples.jsm.loaders.NearestFilter;
import three.js.examples.jsm.loaders.RepeatWrapping;

class MaterialBuilder {

    var manager;
    var textureLoader;
    var tgaLoader;
    var crossOrigin;
    var resourcePath;

    public function new(manager) {
        this.manager = manager;
        this.textureLoader = new TextureLoader(this.manager);
        this.tgaLoader = null;
        this.crossOrigin = 'anonymous';
        this.resourcePath = undefined;
    }

    public function setCrossOrigin(crossOrigin) {
        this.crossOrigin = crossOrigin;
        return this;
    }

    public function setResourcePath(resourcePath) {
        this.resourcePath = resourcePath;
        return this;
    }

    public function build(data, geometry /*, onProgress, onError */) {
        var materials = [];
        var textures = {};
        this.textureLoader.setCrossOrigin(this.crossOrigin);
        for (i in 0...data.metadata.materialCount) {
            var material = data.materials[i];
            var params = {userData: {MMD: {}}};
            if (material.name !== undefined) params.name = material.name;
            params.diffuse = new Color().setRGB(material.diffuse[0], material.diffuse[1], material.diffuse[2], SRGBColorSpace);
            params.opacity = material.diffuse[3];
            params.specular = new Color().setRGB(...material.specular, SRGBColorSpace);
            params.shininess = material.shininess;
            params.emissive = new Color().setRGB(...material.ambient, SRGBColorSpace);
            params.transparent = params.opacity !== 1.0;
            params.fog = true;
            params.blending = CustomBlending;
            params.blendSrc = SrcAlphaFactor;
            params.blendDst = OneMinusSrcAlphaFactor;
            params.blendSrcAlpha = SrcAlphaFactor;
            params.blendDstAlpha = DstAlphaFactor;
            if (data.metadata.format === 'pmx' && (material.flag & 0x1) === 1) {
                params.side = DoubleSide;
            } else {
                params.side = params.opacity === 1.0 ? FrontSide : DoubleSide;
            }
            if (data.metadata.format === 'pmd') {
                if (material.fileName) {
                    var fileName = material.fileName;
                    var fileNames = fileName.split('*');
                    params.map = this._loadTexture(fileNames[0], textures);
                    if (fileNames.length > 1) {
                        var extension = fileNames[1].slice(-4).toLowerCase();
                        params.matcap = this._loadTexture(fileNames[1], textures);
                        params.matcapCombine = extension === '.sph' ? MultiplyOperation : AddOperation;
                    }
                }
                var toonFileName = (material.toonIndex === -1) ? 'toon00.bmp' : data.toonTextures[material.toonIndex].fileName;
                params.gradientMap = this._loadTexture(toonFileName, textures, {isToonTexture: true, isDefaultToonTexture: this._isDefaultToonTexture(toonFileName)});
                params.userData.outlineParameters = {thickness: material.edgeFlag === 1 ? 0.003 : 0.0, color: [0, 0, 0], alpha: 1.0, visible: material.edgeFlag === 1};
            } else {
                if (material.textureIndex !== -1) {
                    params.map = this._loadTexture(data.textures[material.textureIndex], textures);
                    params.userData.MMD.mapFileName = data.textures[material.textureIndex];
                }
                if (material.envTextureIndex !== -1 && (material.envFlag === 1 || material.envFlag == 2)) {
                    params.matcap = this._loadTexture(data.textures[material.envTextureIndex], textures);
                    params.userData.MMD.matcapFileName = data.textures[material.envTextureIndex];
                    params.matcapCombine = material.envFlag === 1 ? MultiplyOperation : AddOperation;
                }
                var toonFileName, isDefaultToon;
                if (material.toonIndex === -1 || material.toonFlag !== 0) {
                    toonFileName = 'toon' + ( '0' + (material.toonIndex + 1) ).slice(-2) + '.bmp';
                    isDefaultToon = true;
                } else {
                    toonFileName = data.textures[material.toonIndex];
                    isDefaultToon = false;
                }
                params.gradientMap = this._loadTexture(toonFileName, textures, {isToonTexture: true, isDefaultToonTexture: isDefaultToon});
                params.userData.outlineParameters = {thickness: material.edgeSize / 300, color: material.edgeColor.slice(0, 3), alpha: material.edgeColor[3], visible: (material.flag & 0x10) !== 0 && material.edgeSize > 0.0};
            }
            if (params.map !== undefined) {
                if (!params.transparent) {
                    this._checkImageTransparency(params.map, geometry, i);
                }
                params.emissive.multiplyScalar(0.2);
            }
            materials.push(new MMDToonMaterial(params));
        }
        if (data.metadata.format === 'pmx') {
            function checkAlphaMorph(elements, materials) {
                for (i in 0...elements.length) {
                    var element = elements[i];
                    if (element.index === -1) continue;
                    var material = materials[element.index];
                    if (material.opacity !== element.diffuse[3]) {
                        material.transparent = true;
                    }
                }
            }
            for (i in 0...data.morphs.length) {
                var morph = data.morphs[i];
                var elements = morph.elements;
                if (morph.type === 0) {
                    for (j in 0...elements.length) {
                        var morph2 = data.morphs[elements[j].index];
                        if (morph2.type !== 8) continue;
                        checkAlphaMorph(morph2.elements, materials);
                    }
                } else if (morph.type === 8) {
                    checkAlphaMorph(elements, materials);
                }
            }
        }
        return materials;
    }

    private function _getTGALoader() {
        if (this.tgaLoader === null) {
            if (TGALoader === undefined) {
                throw new Error('THREE.MMDLoader: Import TGALoader');
            }
            this.tgaLoader = new TGALoader(this.manager);
        }
        return this.tgaLoader;
    }

    private function _isDefaultToonTexture(name) {
        if (name.length !== 10) return false;
        return /toon(10|0[0-9])\.bmp/.test(name);
    }

    private function _loadTexture(filePath, textures, params, onProgress, onError) {
        params = params || {};
        var scope = this;
        var fullPath;
        if (params.isDefaultToonTexture === true) {
            var index;
            try {
                index = parseInt(filePath.match(/toon([0-9]{2})\.bmp$/)[1]);
            } catch (e) {
                console.warn('THREE.MMDLoader: ' + filePath + ' seems like a ' + 'not right default texture path. Using toon00.bmp instead.');
                index = 0;
            }
            fullPath = DEFAULT_TOON_TEXTURES[index];
        } else {
            fullPath = this.resourcePath + filePath;
        }
        if (textures[fullPath] !== undefined) return textures[fullPath];
        var loader = this.manager.getHandler(fullPath);
        if (loader === null) {
            loader = (filePath.slice(-4).toLowerCase() === '.tga') ? this._getTGALoader() : this.textureLoader;
        }
        var texture = loader.load(fullPath, function(t) {
            if (params.isToonTexture === true) {
                t.image = scope._getRotatedImage(t.image);
                t.magFilter = NearestFilter;
                t.minFilter = NearestFilter;
            }
            t.flipY = false;
            t.wrapS = RepeatWrapping;
            t.wrapT = RepeatWrapping;
            t.colorSpace = SRGBColorSpace;
            for (i in 0...texture.readyCallbacks.length) {
                texture.readyCallbacks[i](texture);
            }
            delete texture.readyCallbacks;
        }, onProgress, onError);
        texture.readyCallbacks = [];
        textures[fullPath] = texture;
        return texture;
    }

    private function _getRotatedImage(image) {
        var canvas = document.createElement('canvas');
        var context = canvas.getContext('2d');
        var width = image.width;
        var height = image.height;
        canvas.width = width;
        canvas.height = height;
        context.clearRect(0, 0, width, height);
        context.translate(width / 2.0, height / 2.0);
        context.rotate(0.5 * Math.PI); // 90.0 * Math.PI / 180.0
        context.translate(-width / 2.0, -height / 2.0);
        context.drawImage(image, 0, 0);
        return context.getImageData(0, 0, width, height);
    }

    private function _checkImageTransparency(map, geometry, groupIndex) {
        map.readyCallbacks.push(function(texture) {
            function createImageData(image) {
                var canvas = document.createElement('canvas');
                canvas.width = image.width;
                canvas.height = image.height;
                var context = canvas.getContext('2d');
                context.drawImage(image, 0, 0);
                return context.getImageData(0, 0, canvas.width, canvas.height);
            }
            function detectImageTransparency(image, uvs, indices) {
                var width = image.width;
                var height = image.height;
                var data = image.data;
                var threshold = 253;
                if (data.length / (width * height) !== 4) return false;
                for (i in 0...indices.length) {
                    var centerUV = {x: 0.0, y: 0.0};
                    for (j in 0...3) {
                        var index = indices[i * 3 + j];
                        var uv = {x: uvs[index * 2 + 0], y: uvs[index * 2 + 1]};
                        if (getAlphaByUv(image, uv) < threshold) return true;
                        centerUV.x += uv.x;
                        centerUV.y += uv.y;
                    }
                    centerUV.x /= 3;
                    centerUV.y /= 3;
                    if (getAlphaByUv(image, centerUV) < threshold) return true;
                }
                return false;
            }
            function getAlphaByUv(image, uv) {
                var width = image.width;
                var height = image.height;
                var x = Math.round(uv.x * width) % width;
                var y = Math.round(uv.y * height) % height;
                if (x < 0) x += width;
                if (y < 0) y += height;
                var index = y * width + x;
                return image.data[index * 4 + 3];
            }
            if (texture.isCompressedTexture === true) {
                if (NON_ALPHA_CHANNEL_FORMATS.includes(texture.format)) {
                    map.transparent = false;
                } else {
                    map.transparent = true;
                }
                return;
            }
            var imageData = texture.image.data !== undefined ? texture.image : createImageData(texture.image);
            var group = geometry.groups[groupIndex];
            if (detectImageTransparency(imageData, geometry.attributes.uv.array, geometry.index.array.slice(group.start, group.start + group.count))) {
                map.transparent = true;
            }
        });
    }

}