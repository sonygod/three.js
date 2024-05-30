class GLTFParser {
    public var json:Dynamic;
    public var extensions:Dynamic;
    public var plugins:Dynamic;
    public var options:Dynamic;
    public var cache:GLTFRegistry;
    public var associations:Map;
    public var primitiveCache:Dynamic;
    public var nodeCache:Dynamic;
    public var meshCache:Dynamic;
    public var cameraCache:Dynamic;
    public var lightCache:Dynamic;
    public var sourceCache:Dynamic;
    public var textureCache:Dynamic;
    public var nodeNamesUsed:Dynamic;
    public var textureLoader:Dynamic;
    public var fileLoader:Dynamic;
    public var isSafari:Bool;
    public var isFirefox:Bool;
    public var firefoxVersion:Int;

    public function new(json:Dynamic, options:Dynamic) {
        this.json = json;
        this.extensions = {};
        this.plugins = {};
        this.options = options;
        this.cache = new GLTFRegistry();
        this.associations = new Map();
        this.primitiveCache = {};
        this.nodeCache = {};
        this.meshCache = { refs: {}, uses: {} };
        this.cameraCache = { refs: {}, uses: {} };
        this.lightCache = { refs: {}, uses: {} };
        this.sourceCache = {};
        this.textureCache = {};
        this.nodeNamesUsed = {};
        this.isSafari = false;
        this.isFirefox = false;
        this.firefoxVersion = -1;
        if (typeof navigator != 'undefined') {
            this.isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent) === true;
            this.isFirefox = navigator.userAgent.indexOf('Firefox') > -1;
            this.firefoxVersion = this.isFirefox ? navigator.userAgent.match(/Firefox\/([0-9]+)\./)[1] : -1;
        }
        if (typeof createImageBitmap == 'undefined' || this.isSafari || (this.isFirefox && this.firefoxVersion < 98)) {
            this.textureLoader = new TextureLoader(this.options.manager);
        } else {
            this.textureLoader = new ImageBitmapLoader(this.options.manager);
        }
        this.textureLoader.setCrossOrigin(this.options.crossOrigin);
        this.textureLoader.setRequestHeader(this.options.requestHeader);
        this.fileLoader = new FileLoader(this.options.manager);
        this.fileLoader.setResponseType('arraybuffer');
        if (this.options.crossOrigin == 'use-credentials') {
            this.fileLoader.setWithCredentials(true);
        }
    }

    public function setExtensions(extensions:Dynamic) {
        this.extensions = extensions;
    }

    public function setPlugins(plugins:Dynamic) {
        this.plugins = plugins;
    }

    public function parse(onLoad:Dynamic, onError:Dynamic) {
        var parser = this;
        var json = this.json;
        var extensions = this.extensions;
        this.cache.removeAll();
        this.nodeCache = {};
        this._invokeAll(function (ext) {
            return ext._markDefs && ext._markDefs();
        });
        Promise.all(this._invokeAll(function (ext) {
            return ext.beforeRoot && ext.beforeRoot();
        })).then(function () {
            return Promise.all([
                parser.getDependencies('scene'),
                parser.getDependencies('animation'),
                parser.getDependencies('camera'),
            ]);
        }).then(function (dependencies) {
            var result = {
                scene: dependencies[0][json.scene || 0],
                scenes: dependencies[0],
                animations: dependencies[1],
                cameras: dependencies[2],
                asset: json.asset,
                parser: parser,
                userData: {}
            };
            addUnknownExtensionsToUserData(extensions, result, json);
            assignExtrasToUserData(result, json);
            return Promise.all(parser._invokeAll(function (ext) {
                return ext.afterRoot && ext.afterRoot(result);
            })).then(function () {
                for (var scene of result.scenes) {
                    scene.updateMatrixWorld();
                }
                onLoad(result);
            });
        }).catch(onError);
    }

    public function _markDefs() {
        var nodeDefs = this.json.nodes || [];
        var skinDefs = this.json.skins || [];
        var meshDefs = this.json.meshes || [];
        for (var skinIndex = 0, skinLength = skinDefs.length; skinIndex < skinLength; skinIndex++) {
            var joints = skinDefs[skinIndex].joints;
            for (var i = 0, il = joints.length; i < il; i++) {
                nodeDefs[joints[i]].isBone = true;
            }
        }
        for (var nodeIndex = 0, nodeLength = nodeDefs.length; nodeIndex < nodeLength; nodeIndex++) {
            var nodeDef = nodeDefs[nodeIndex];
            if (nodeDef.mesh != undefined) {
                this._addNodeRef(this.meshCache, nodeDef.mesh);
                if (nodeDef.skin != undefined) {
                    meshDefs[nodeDef.mesh].isSkinnedMesh = true;
                }
            }
            if (nodeDef.camera != undefined) {
                this._addNodeRef(this.cameraCache, nodeDef.camera);
            }
        }
    }

    public function _addNodeRef(cache:Dynamic, index:Dynamic) {
        if (index == undefined) return;
        if (cache.refs[index] == undefined) {
            cache.refs[index] = cache.uses[index] = 0;
        }
        cache.refs[index]++;
    }

    public function _getNodeRef(cache:Dynamic, index:Dynamic, object:Dynamic) {
        if (cache.refs[index] <= 1) return object;
        var ref = object.clone();
        var updateMappings = function (original:Dynamic, clone:Dynamic) {
            var mappings = this.associations.get(original);
            if (mappings != null) {
                this.associations.set(clone, mappings);
            }
            for (var i = 0, child of original.children.iterator()) {
                updateMappings(child, clone.children[i]);
            }
        };
        updateMappings(object, ref);
        ref.name += '_instance_' + (cache.uses[index]++);
        return ref;
    }

    public function _invokeOne(func:Dynamic) {
        var extensions = Object.values(this.plugins);
        extensions.push(this);
        for (var i = 0; i < extensions.length; i++) {
            var result = func(extensions[i]);
            if (result) return result;
        }
        return null;
    }

    public function _invokeAll(func:Dynamic) {
        var extensions = Object.values(this.plugins);
        extensions.unshift(this);
        var pending = [];
        for (var i = 0; i < extensions.length; i++) {
            var result = func(extensions[i]);
            if (result) pending.push(result);
        }
        return pending;
    }

    public function getDependency(type:String, index:Dynamic) {
        var cacheKey = type + ':' + index;
        var dependency = this.cache.get(cacheKey);
        if (!dependency) {
            switch (type) {
                case 'scene':
                    dependency = this.loadScene(index);
                    break;
                case 'node':
                    dependency = this._invokeOne(function (ext) {
                        return ext.loadNode && ext.loadNode(index);
                    });
                    break;
                case 'mesh':
                    dependency = this._invokeOne(function (ext) {
                        return ext.loadMesh && ext.loadMesh(index);
                    });
                    break;
                case 'accessor':
                    dependency = this.loadAccessor(index);
                    break;
                case 'bufferView':
                    dependency = this._invokeOne(function (ext) {
                        return ext.loadBufferView && ext.loadBufferView(index);
                    });
                    break;
                case 'buffer':
                    dependency = this.loadBuffer(index);
                    break;
                case 'material':
                    dependency = this._invokeOne(function (ext) {
                        return ext.loadMaterial && ext.loadMaterial(index);
                    });
                    break;
                case 'texture':
                    dependency = this._invokeOne(function (ext) {
                        return ext.loadTexture && ext.loadTexture(index);
                    });
                    break;
                case 'skin':
                    dependency = this.loadSkin(index);
                    break;
                case 'animation':
                    dependency = this._invokeOne(function (ext) {
                        return ext.loadAnimation && ext.loadAnimation(index);
                    });
                    break;
                case 'camera':
                    dependency = this.loadCamera(index);
                    break;
                default:
                    dependency = this._invokeOne(function (ext) {
                        return ext != this && ext.getDependency && ext.getDependency(type, index);
                    });
                    if (!dependency) {
                        throw new Error('Unknown type: ' + type);
                    }
                    break;
            }
            this.cache.add(cacheKey, dependency);
        }
        return dependency;
    }

    public function getDependencies(type:String) {
        var dependencies = this.cache.get(type);
        if (!dependencies) {
            var parser = this;
            var defs = this.json[type + (type == 'mesh' ? 'es' : 's')];
            dependencies = Promise.all(defs.map(function (def, index) {
                return parser.getDependency(type, index);
            }));
            this.cache.add(type, dependencies);
        }
        return dependencies;
    }

    public function loadBuffer(bufferIndex:Dynamic) {
        var bufferDef = this.json.buffers[bufferIndex];
        var loader = this.fileLoader;
        if (bufferDef.type && bufferDef.type != 'arraybuffer') {
            throw new Error('THREE.GLTFLoader: ' + bufferDef.type + ' buffer type is not supported.');
        }
        if (bufferDef.uri == undefined && bufferIndex == 0) {
            return Promise.resolve(this.extensions[EXTENSIONS.KHR_BINARY_GLTF].body);
        }
        var options = this.options;
        return new Promise(function (resolve, reject) {
            loader.load(LoaderUtils.resolveURL(bufferDef.uri, options.path), resolve, undefined, function () {
                reject(new Error('THREE.GLTFLoader: Failed to load buffer "' + bufferDef.uri + '".'));
            });
        });
    }

    public function loadBufferView(bufferViewIndex:Dynamic) {
        var bufferViewDef = this.json.bufferViews[bufferViewIndex];
        return this.getDependency('buffer', bufferViewDef.buffer).then(function (buffer) {
            var byteLength = bufferViewDef.byteLength || 0;
            var byteOffset = bufferViewDef.byteOffset || 0;
            return buffer.slice(byteOffset, byteOffset + byteLength);
        });
    }

    public function loadAccessor(accessorIndex:Dynamic) {
        var parser = this;
        var json = this.json;
        var accessorDef = this.json.accessors[accessorIndex];
        if (accessorDef.bufferView == undefined && accessorDef.sparse == undefined) {
            var itemSize = WEBGL_TYPE_SIZES[accessorDef.type];
            var TypedArray = WEBGL_COMPONENT_TYPES[accessorDef.componentType];
            var normalized = accessorDef.normalized == true;
            var array = new TypedArray(accessorDef.count * itemSize);
            return Promise.resolve(new BufferAttribute(array, itemSize, normalized));
        }
        var pendingBufferViews = [];
        if (accessorDef.bufferView != undefined) {
            pendingBufferViews.push(this.getDependency('bufferView', accessorDef.bufferView));
        } else {
            pendingBufferViews.push(null);
        }
        if (accessorDef.sparse != undefined) {
            pendingBufferViews.push(this.getDependency('bufferView', accessorDef.sparse.indices.bufferView));
            pendingBufferViews.push(this.getDependency('bufferView', accessorDef.sparse.values.bufferView));
        }
        return Promise.all(pendingBufferViews).then(function (bufferViews) {
            var bufferView = bufferViews[0];
            var itemSize = WEBGL_TYPE_SIZES[accessorDef.type];
            var TypedArray = WEBGL_COMPONENT_TYPES[accessorDef.componentpartum];
            var elementBytes = TypedArray.BYTES_PER_ELEMENT;
            var itemBytes = elementBytes * itemSize;
            var byteOffset = accessorDef.byteOffset || 0;
            var byteStride = accessorDef.bufferView != undefined ? json.bufferViews[accessorDef.bufferView].byteStride : undefined;
            var normalized = accessorDef.normalized == true;
            var array, bufferAttribute;
            if (byteStride && byteStride != itemBytes) {
                var ibSlice = Math.floor(byteOffset / byteStride);
                var ibCacheKey = 'InterleavedBuffer:' + accessorDef.bufferView + ':' + accessorDef.componentType + ':' + ibSlice + ':' + accessorDef.count;
                var ib = parser.cache.get(ibCacheKey);
                if (!ib) {
                    array = new TypedArray(bufferView, ibSlice * byteStride, accessorDef.count * byteStride / elementBytes);
                    ib = new InterleavedBuffer(array, byteStride / elementBytes);
                    parser.cache.add(ibCacheKey, ib);
                }
                bufferAttribute = new InterleavedBufferAttribute(ib, itemSize, (byteOffset % byteStride) / elementBytes, normalized);
            } else {
                if (bufferView == null) {
                    array = new TypedArray(accessorDef.count * itemSize);
                } else {
                    array = new TypedArray(bufferView, byteOffset, accessorDef.count * itemSize);
                }
                bufferAttribute = new BufferAttribute(array, itemSize, normalized);
            }
            if (accessorDef.sparse != undefined) {
                var itemSizeIndices = WEBGL_TYPE_SIZES.SCALAR;
                var TypedArrayIndices = WEBGL_COMPONENT_TYPES[accessorDef.sparse.indices.componentType];
                var byteOffsetIndices = accessorDef.sparse.indices.byteOffset || 0;
                var byteOffsetValues = accessorDef.sparse.values.byteOffset || 0;
                var sparseIndices = new TypedArrayIndices(bufferViews[1], byteOffsetIndices, accessorDef.sparse.count * itemSizeIndices);
                var sparseValues = new TypedArray(bufferViews[2], byteOffsetValues, accessorDef.sparse.count * itemSize);
                if (bufferView != null) {
                    bufferAttribute = new BufferAttribute(bufferAttribute.array.slice(), bufferAttribute.itemSize, bufferAttribute.normalized);
                }
                for (var i = 0, il = sparseIndices.length; i < il; i++) {
                    var index = sparseIndices[i];
                    bufferAttribute.setX(index, sparseValues[i * itemSize]);
                    if (itemSize >= 2) bufferAttribute.setY(index, sparseValues[i * itemSize + 1]);
                    if (itemSize >= 3) bufferAttribute.setZ(index, sparseValues[i * itemSize + 2]);
                    if (itemSize >= 4) bufferAttribute.setW(index, sparseValues[i * itemSize + 3]);
                    if (itemSize >= 5) throw new Error('THREE.GLTFLoader: Unsupported itemSize in sparse BufferAttribute.');
                }
            }
            return bufferAttribute;
        });
    }

    public function loadTexture(textureIndex:Dynamic) {
        var json = this.json;
        var options = this.options;
        var textureDef = json.textures[textureIndex];
        var sourceIndex = textureDef.source;
        var sourceDef = json.images[sourceIndex];
        var loader = this.textureLoader;
        if (sourceDef.uri) {
            var handler = options.manager.getHandler(sourceDef.uri);
            if (handler != null) loader = handler;
        }
        return this.loadTextureImage(textureIndex, sourceIndex, loader);
    }

    public function loadTextureImage(textureIndex:Dynamic, sourceIndex:Dynamic, loader:Dynamic) {
        var parser = this;
        var json = this.json;
        var textureDef = json.textures[textureIndex];
        var sourceDef = json.images[sourceIndex];
        var cacheKey = (sourceDef.uri || sourceDef.bufferView) + ':' + textureDef.sampler;
        if (this.textureCache[cacheKey]) {
            return this.textureCache[cacheKey];
        }
        var promise = this.loadImageSource(sourceIndex, loader).then(function (texture) {
            texture.flipY = false;
            texture.name = textureDef.name || sourceDef.name || '';
            if (texture.name == '' && typeof sourceDef.uri == 'string' && !sourceDef.uri.startsWith('data:image/')) {
                texture.name = sourceDef.uri;
            }
            var samplers = json.samplers || {};
            var sampler = samplers[textureDef.sampler] || {};
            texture.magFilter = WEBGL_FILTERS[sampler.magFilter] || LinearFilter;
            texture.minFilter = WEBGL_FILTERS[sampler.minFilter] || LinearMipmapLinearFilter;
            texture.wrapS = WEBGL_WRAPPINGS[sampler.wrapS] || RepeatWrapping;
            texture.wrapT = WEBGL_WRAPPINGS[sampler.wrapT] ;
            parser.associations.set(texture, {textures: textureIndex});
            return texture;
        }).catch(function () {
            return null;
        });
        this.textureCache[cacheKey] = promise;
        return promise;
    }

    public function loadImageSource(sourceIndex:Dynamic, loader:Dynamic) {
        var parser = this;
        var json = this.json;
        var options = this.options;
        if (this.sourceCache[sourceIndex] != undefined) {
            return this.sourceCache[sourceIndex].then(function (texture) {
                return texture