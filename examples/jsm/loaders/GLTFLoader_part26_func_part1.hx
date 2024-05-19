package three.js.examples.jsm.loaders;

import haxe.ds.StringMap;
import js.html.ImageBitmap;
import js.Promise;
import three.js.loaders.GLTFRegistry;
import three.js.loaders.TextureLoader;
import three.js.loaders.FileLoader;
import three.js.loaders.ImageBitmapLoader;

class GLTFParser {
    public var json:Dynamic;
    public var extensions:StringMap<Dynamic>;
    public var plugins:StringMap<Dynamic>;
    public var options:Dynamic;
    public var cache:GLTFRegistry;
    public var associations:StringMap<Dynamic>;
    public var primitiveCache:Dynamic;
    public var nodeCache:Dynamic;
    public var meshCache:Dynamic;
    public var cameraCache:Dynamic;
    public var lightCache:Dynamic;
    public var sourceCache:Dynamic;
    public var textureCache:Dynamic;
    public var nodeNamesUsed:StringMap<Bool>;
    public var textureLoader:TextureLoader;
    public var fileLoader:FileLoader;

    public function new(json:Dynamic = {}, options:Dynamic = {}) {
        this.json = json;
        this.extensions = new StringMap<Dynamic>();
        this.plugins = new StringMap<Dynamic>();
        this.options = options;

        this.cache = new GLTFRegistry();
        this.associations = new StringMap<Dynamic>();
        this.primitiveCache = {};
        this.nodeCache = {};
        this.meshCache = { refs: {}, uses: {} };
        this.cameraCache = { refs: {}, uses: {} };
        this.lightCache = { refs: {}, uses: {} };
        this.sourceCache = {};
        this.textureCache = {};
        this.nodeNamesUsed = new StringMap<Bool>();

        var isSafari = false;
        var isFirefox = false;
        var firefoxVersion = -1;

        if (untyped navigator != null) {
            isSafari = ~/^((?!chrome|android).*safari/i.test(untyped navigator.userAgent) == true;
            isFirefox = untyped navigator.userAgent.indexOf('Firefox') > -1;
            firefoxVersion = isFirefox ? untyped navigator.userAgent.match(/Firefox\/([0-9]+)/)[1] : -1;
        }

        if (untyped createImageBitmap == null || isSafari || (isFirefox && firefoxVersion < 98)) {
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

    public function parse(onLoad:Dynamic -> Void, onError:Dynamic -> Void) {
        var parser = this;
        var json = this.json;
        var extensions = this.extensions;

        // Clear the loader cache
        this.cache.removeAll();
        this.nodeCache = {};

        // Mark the special nodes/meshes in json for efficient parse
        this._invokeAll(function(ext) {
            return ext._markDefs && ext._markDefs();
        });

        Promise.all(this._invokeAll(function(ext) {
            return ext.beforeRoot && ext.beforeRoot();
        })).then(function() {
            return Promise.all([
                parser.getDependencies('scene'),
                parser.getDependencies('animation'),
                parser.getDependencies('camera'),
            ]);
        }).then(function(dependencies) {
            var result = {
                scene: dependencies[0][json.scene || 0],
                scenes: dependencies[0],
                animations: dependencies[1],
                cameras: dependencies[2],
                asset: json.asset,
                parser: parser,
                userData: {},
            };

            addUnknownExtensionsToUserData(extensions, result, json);

            assignExtrasToUserData(result, json);

            return Promise.all(parser._invokeAll(function(ext) {
                return ext.afterRoot && ext.afterRoot(result);
            })).then(function() {
                for (scene in result.scenes) {
                    scene.updateMatrixWorld();
                }

                onLoad(result);
            });
        }).catchError(onError);
    }

    public function _markDefs() {
        var nodeDefs = json.nodes || [];
        var skinDefs = json.skins || [];
        var meshDefs = json.meshes || [];

        // Nothing in the node definition indicates whether it is a Bone or an
        // Object3D. Use the skins' joint references to mark bones.
        for (skinIndex in 0...skinDefs.length) {
            var joints = skinDefs[skinIndex].joints;

            for (i in 0...joints.length) {
                nodeDefs[joints[i]].isBone = true;
            }
        }

        // Iterate over all nodes, marking references to shared resources,
        // as well as skeleton joints.
        for (nodeIndex in 0...nodeDefs.length) {
            var nodeDef = nodeDefs[nodeIndex];

            if (nodeDef.mesh != null) {
                this._addNodeRef(this.meshCache, nodeDef.mesh);

                // Nothing in the mesh definition indicates whether it is
                // a SkinnedMesh or Mesh. Use the node's mesh reference
                // to mark SkinnedMesh if node has skin.
                if (nodeDef.skin != null) {
                    meshDefs[nodeDef.mesh].isSkinnedMesh = true;
                }
            }

            if (nodeDef.camera != null) {
                this._addNodeRef(this.cameraCache, nodeDef.camera);
            }
        }
    }

    public function _addNodeRef(cache:Dynamic, index:Int) {
        if (index == null) return;

        if (cache.refs[index] == null) {
            cache.refs[index] = cache.uses[index] = 0;
        }

        cache.refs[index]++;
    }

    public function _getNodeRef(cache:Dynamic, index:Int, object:Dynamic) {
        if (cache.refs[index] <= 1) return object;

        var ref = object.clone();

        // Propagates mappings to the cloned object, prevents mappings on the
        // original object from being lost.
        var updateMappings = function(original:Dynamic, clone:Dynamic) {
            var mappings = this.associations.get(original);
            if (mappings != null) {
                this.associations.set(clone, mappings);
            }

            for (child in original.children) {
                updateMappings(child, clone.children[child.index]);
            }
        };

        updateMappings(object, ref);

        ref.name += '_instance_' + (cache.uses[index]++);

        return ref;
    }

    public function _invokeOne(func:Dynamic -> Dynamic) {
        var extensions = [for (ext in this.plugins) ext];
        extensions.unshift(this);

        for (ext in extensions) {
            var result = func(ext);
            if (result != null) return result;
        }

        return null;
    }

    public function _invokeAll(func:Dynamic -> Dynamic) {
        var extensions = [for (ext in this.plugins) ext];
        extensions.unshift(this);

        var pending = [];

        for (ext in extensions) {
            var result = func(ext);
            if (result != null) pending.push(result);
        }

        return pending;
    }

    public function getDependency(type:String, index:Int) {
        var cacheKey = type + ':' + index;
        var dependency = this.cache.get(cacheKey);

        if (dependency == null) {
            switch (type) {
                case 'scene':
                    dependency = this.loadScene(index);
                    break;
                case 'node':
                    dependency = this._invokeOne(function(ext) {
                        return ext.loadNode && ext.loadNode(index);
                    });
                    break;
                case 'mesh':
                    dependency = this._invokeOne(function(ext) {
                        return ext.loadMesh && ext.loadMesh(index);
                    });
                    break;
                case 'accessor':
                    dependency = this.loadAccessor(index);
                    break;
                case 'bufferView':
                    dependency = this._invokeOne(function(ext) {
                        return ext.loadBufferView && ext.loadBufferView(index);
                    });
                    break;
                case 'buffer':
                    dependency = this.loadBuffer(index);
                    break;
                case 'material':
                    dependency = this._invokeOne(function(ext) {
                        return ext.loadMaterial && ext.loadMaterial(index);
                    });
                    break;
                case 'texture':
                    dependency = this._invokeOne(function(ext) {
                        return ext.loadTexture && ext.loadTexture(index);
                    });
                    break;
                case 'skin':
                    dependency = this.loadSkin(index);
                    break;
                case 'animation':
                    dependency = this._invokeOne(function(ext) {
                        return ext.loadAnimation && ext.loadAnimation(index);
                    });
                    break;
                case 'camera':
                    dependency = this.loadCamera(index);
                    break;
                default:
                    dependency = this._invokeOne(function(ext) {
                        return ext != this && ext.getDependency && ext.getDependency(type, index);
                    });

                    if (dependency == null) {
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

        if (dependencies == null) {
            var parser = this;
            var defs = this.json[type + (type == 'mesh' ? 'es' : 's')] || [];

            dependencies = Promise.all(defs.map(function(def, index) {
                return parser.getDependency(type, index);
            }));

            this.cache.add(type, dependencies);
        }

        return dependencies;
    }

    public function loadBuffer(bufferIndex:Int) {
        var bufferDef = this.json.buffers[bufferIndex];
        var loader = this.fileLoader;

        if (bufferDef.type && bufferDef.type != 'arraybuffer') {
            throw new Error('THREE.GLTFLoader: ' + bufferDef.type + ' buffer type is not supported.');
        }

        // If present, GLB container is required to be the first buffer.
        if (bufferDef.uri == null && bufferIndex == 0) {
            return Promise.resolve(this.extensions[EXTENSIONS.KHR_BINARY_GLTF].body);
        }

        var options = this.options;

        return new Promise(function(resolve, reject) {
            loader.load(LoaderUtils.resolveURL(bufferDef.uri, options.path), resolve, undefined, function() {
                reject(new Error('THREE.GLTFLoader: Failed to load buffer "' + bufferDef.uri + '".'));
            });
        });
    }

    public function loadBufferView(bufferViewIndex:Int) {
        var bufferViewDef = this.json.bufferViews[bufferViewIndex];

        return this.getDependency('buffer', bufferViewDef.buffer).then(function(buffer) {
            var byteLength = bufferViewDef.byteLength || 0;
            var byteOffset = bufferViewDef.byteOffset || 0;
            return buffer.slice(byteOffset, byteOffset + byteLength);
        });
    }
}