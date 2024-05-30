package three.js.examples.jsm.nodes.materials;

import three.Material;

class NodeMaterial extends Material {
    public var isNodeMaterial:Bool = true;
    
    public var type:String;
    
    public var forceSinglePass:Bool = false;
    
    public var fog:Bool = true;
    public var lights:Bool = true;
    public var normals:Bool = true;
    
    public var lightsNode:Dynamic;
    public var envNode:Dynamic;
    public var aoNode:Dynamic;
    
    public var colorNode:Dynamic;
    public var normalNode:Dynamic;
    public var opacityNode:Dynamic;
    public var backdropNode:Dynamic;
    public var backdropAlphaNode:Dynamic;
    public var alphaTestNode:Dynamic;
    
    public var positionNode:Dynamic;
    
    public var depthNode:Dynamic;
    public var shadowNode:Dynamic;
    public var shadowPositionNode:Dynamic;
    
    public var outputNode:Dynamic;
    
    public var fragmentNode:Dynamic;
    public var vertexNode:Dynamic;
    
    public function new() {
        super();
        
        this.type = Type.getClassName(Type.getClass(this));
    }
    
    public function customProgramCacheKey():String {
        return this.type + getCacheKey(this);
    }
    
    public function build(builder:Dynamic) {
        this.setup(builder);
    }
    
    public function setup(builder:Dynamic) {
        // < VERTEX STAGE >
        
        builder.addStack();
        
        builder.stack.outputNode = this.vertexNode != null ? this.vertexNode : this.setupPosition(builder);
        
        builder.addFlow('vertex', builder.removeStack());
        
        // < FRAGMENT STAGE >
        
        builder.addStack();
        
        var resultNode:Dynamic;
        
        var clippingNode = this.setupClipping(builder);
        
        if (this.depthWrite) this.setupDepth(builder);
        
        if (this.fragmentNode == null) {
            if (this.normals) this.setupNormal(builder);
            
            this.setupDiffuseColor(builder);
            this.setupVariants(builder);
            
            var outgoingLightNode = this.setupLighting(builder);
            
            if (clippingNode != null) builder.stack.add(clippingNode);
            
            // force unsigned floats - useful for RenderTargets
            
            var basicOutput = vec4(outgoingLightNode, diffuseColor.a).max(0);
            
            resultNode = this.setupOutput(builder, basicOutput);
            
            // OUTPUT NODE
            
            output.assign(resultNode);
            
            if (this.outputNode != null) resultNode = this.outputNode;
        } else {
            var fragmentNode = this.fragmentNode;
            
            if (!fragmentNode.isOutputStructNode) {
                fragmentNode = vec4(fragmentNode);
            }
            
            resultNode = this.setupOutput(builder, fragmentNode);
        }
        
        builder.stack.outputNode = resultNode;
        
        builder.addFlow('fragment', builder.removeStack());
    }
    
    public function setupClipping(builder:Dynamic):Dynamic {
        if (builder.clippingContext == null) return null;
        
        var globalClippingCount = builder.clippingContext.globalClippingCount;
        var localClippingCount = builder.clippingContext.localClippingCount;
        
        var result:Dynamic = null;
        
        if (globalClippingCount || localClippingCount) {
            if (this.alphaToCoverage) {
                // to be added to flow when the color/alpha value has been determined
                result = clippingAlpha();
            } else {
                builder.stack.add(clipping());
            }
        }
        
        return result;
    }
    
    public function setupDepth(builder:Dynamic) {
        var renderer = builder.renderer;
        
        // Depth
        
        var depthNode = this.depthNode;
        
        if (depthNode == null && renderer.logarithmicDepthBuffer) {
            var fragDepth = modelViewProjection().w.add(1);
            
            depthNode = fragDepth.log2().mul(cameraLogDepth).mul(0.5);
        }
        
        if (depthNode != null) {
            depthPixel.assign(depthNode).append();
        }
    }
    
    public function setupPosition(builder:Dynamic) {
        var object = builder.object;
        var geometry = object.geometry;
        
        builder.addStack();
        
        // Vertex
        
        if (geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color) {
            morphReference(object).append();
        }
        
        if (object.isSkinnedMesh) {
            skinningReference(object).append();
        }
        
        if (this.displacementMap) {
            var displacementMap = materialReference('displacementMap', 'texture');
            var displacementScale = materialReference('displacementScale', 'float');
            var displacementBias = materialReference('displacementBias', 'float');
            
            positionLocal.addAssign(normalLocal.normalize().mul((displacementMap.x.mul(displacementScale).add(displacementBias))));
        }
        
        if (object.isBatchedMesh) {
            batch(object).append();
        }
        
        if (object.instanceMatrix && object.instanceMatrix.isInstancedBufferAttribute) {
            instance(object).append();
        }
        
        if (this.positionNode != null) {
            positionLocal.assign(this.positionNode);
        }
        
        var mvp = modelViewProjection();
        
        builder.context.vertex = builder.removeStack();
        builder.context.mvp = mvp;
        
        return mvp;
    }
    
    public function setupDiffuseColor(builder:Dynamic) {
        var colorNode = this.colorNode != null ? vec4(this.colorNode) : materialColor;
        
        // VERTEX COLORS
        
        if (this.vertexColors && geometry.hasAttribute('color')) {
            colorNode = vec4(colorNode.xyz.mul(attribute('color', 'vec3')), colorNode.a);
        }
        
        // Instanced colors
        
        if (object.instanceColor) {
            var instanceColor = varyingProperty('vec3', 'vInstanceColor');
            colorNode = instanceColor.mul(colorNode);
        }
        
        // COLOR
        
        diffuseColor.assign(colorNode);
        
        // OPACITY
        
        var opacityNode = this.opacityNode != null ? float(this.opacityNode) : materialOpacity;
        diffuseColor.a.assign(diffuseColor.a.mul(opacityNode));
        
        // ALPHA TEST
        
        if (this.alphaTestNode != null || this.alphaTest > 0) {
            var alphaTestNode = this.alphaTestNode != null ? float(this.alphaTestNode) : materialAlphaTest;
            diffuseColor.a.lessThanEqual(alphaTestNode).discard();
        }
    }
    
    public function setupVariants(builder:Dynamic) {
        // Interface function.
    }
    
    public function setupNormal() {
        // NORMAL VIEW
        
        if (this.flatShading) {
            var normalNode = positionView.dFdx().cross(positionView.dFdy()).normalize();
            transformedNormalView.assign(normalNode.mul(faceDirection));
        } else {
            var normalNode = this.normalNode != null ? vec3(this.normalNode) : materialNormal;
            transformedNormalView.assign(normalNode.mul(faceDirection));
        }
    }
    
    public function getEnvNode(builder:Dynamic):Dynamic {
        var node:Dynamic = null;
        
        if (this.envNode != null) {
            node = this.envNode;
        } else if (this.envMap != null) {
            node = this.envMap.isCubeTexture ? cubeTexture(this.envMap) : texture(this.envMap);
        } else if (builder.environmentNode != null) {
            node = builder.environmentNode;
        }
        
        return node;
    }
    
    public function setupLights(builder:Dynamic):Dynamic {
        var envNode:Dynamic = this.getEnvNode(builder);
        
        var materialLightsNode:Array<Dynamic> = [];
        
        if (envNode != null) {
            materialLightsNode.push(new EnvironmentNode(envNode));
        }
        
        if (builder.material.lightMap) {
            materialLightsNode.push(new IrradianceNode(materialReference('lightMap', 'texture')));
        }
        
        if (this.aoNode != null || builder.material.aoMap) {
            var aoNode:Dynamic = this.aoNode != null ? this.aoNode : texture(builder.material.aoMap);
            materialLightsNode.push(new AONode(aoNode));
        }
        
        var lightsN:Dynamic = this.lightsNode != null ? this.lightsNode : builder.lightsNode;
        
        if (materialLightsNode.length > 0) {
            lightsN = lightsNode([].concat(lightsN.lightNodes, materialLightsNode));
        }
        
        return lightsN;
    }
    
    public function setupLightingModel(builder:Dynamic):Void {
        // Interface function.
    }
    
    public function setupLighting(builder:Dynamic):Dynamic {
        var material = builder.material;
        var backdropNode:Dynamic = this.backdropNode;
        var backdropAlphaNode:Dynamic = this.backdropAlphaNode;
        
        // OUTGOING LIGHT
        
        var lights:Bool = this.lights || this.lightsNode != null;
        var lightsNode:Dynamic = lights ? this.setupLights(builder) : null;
        
        var outgoingLightNode:Dynamic = diffuseColor.rgb;
        
        if (lightsNode != null && lightsNode.hasLight) {
            var lightingModel = this.setupLightingModel(builder);
            outgoingLightNode = lightingContext(lightsNode, lightingModel, backdropNode, backdropAlphaNode);
        } else if (backdropNode != null) {
            outgoingLightNode = vec3(backdropAlphaNode != null ? mix(outgoingLightNode, backdropNode, backdropAlphaNode) : backdropNode);
        }
        
        // EMISSIVE
        
        if (this.emissive != null && this.emissive.isNode) {
            outgoingLightNode = outgoingLightNode.add(vec3(this.emissive));
        } else if (material.emissive != null && material.emissive.isColor) {
            outgoingLightNode = outgoingLightNode.add(vec3(material.emissive));
        }
        
        return outgoingLightNode;
    }
    
    public function setupOutput(builder:Dynamic, outputNode:Dynamic):Dynamic {
        // FOG
        
        var fogNode = builder.fogNode;
        
        if (fogNode != null) {
            outputNode = vec4(fogNode.mix(outputNode.rgb, fogNode.colorNode), outputNode.a);
        }
        
        return outputNode;
    }
    
    public function setDefaultValues(material:Dynamic):Void {
        for (field in Reflect.fields(material)) {
            var value = Reflect.field(material, field);
            
            if (!Reflect.hasField(this, field)) {
                Reflect.setField(this, field, value.clone());
            }
        }
        
        var descriptors = Reflect.fields(material.constructor.prototype);
        
        for (field in descriptors) {
            if (!Reflect.hasField(this.constructor.prototype, field) && descriptors[field].get != null) {
                Reflect.setField(this.constructor.prototype, field, descriptors[field]);
            }
        }
    }
    
    public function toJSON(meta:Dynamic):Dynamic {
        if (meta == null || Std.isOfType(meta, String)) {
            meta = {
                textures: {},
                images: {},
                nodes: {}
            };
        }
        
        var data = Material.prototype.toJSON.call(this, meta);
        var nodeChildren:Array<Dynamic> = getNodeChildren(this);
        
        data.inputNodes = {};
        
        for (child in nodeChildren) {
            data.inputNodes[child.property] = child.childNode.toJSON(meta).uuid;
        }
        
        if (meta == null) {
            var textures:Array<Dynamic> = [];
            var images:Array<Dynamic> = [];
            var nodes:Array<Dynamic> = [];
            
            for (key in Reflect.fields(meta.textures)) {
                textures.push(Reflect.field(meta.textures, key));
            }
            
            for (key in Reflect.fields(meta.images)) {
                images.push(Reflect.field(meta.images, key));
            }
            
            for (key in Reflect.fields(meta.nodes)) {
                nodes.push(Reflect.field(meta.nodes, key));
            }
            
            if (textures.length > 0) data.textures = textures;
            if (images.length > 0) data.images = images;
            if (nodes.length > 0) data.nodes = nodes;
        }
        
        return data;
    }
    
    public function copy(source:Dynamic):NodeMaterial {
        this.lightsNode = source.lightsNode;
        this.envNode = source.envNode;
        
        this.colorNode = source.colorNode;
        this.normalNode = source.normalNode;
        this.opacityNode = source.opacityNode;
        this.backdropNode = source.backdropNode;
        this.backdropAlphaNode = source.backdropAlphaNode;
        this.alphaTestNode = source.alphaTestNode;
        
        this.positionNode = source.positionNode;
        
        this.depthNode = source.depthNode;
        this.shadowNode = source.shadowNode;
        this.shadowPositionNode = source.shadowPositionNode;
        
        this.outputNode = source.outputNode;
        
        this.fragmentNode = source.fragmentNode;
        this.vertexNode = source.vertexNode;
        
        return cast super.copy(source);
    }
    
    public static function fromMaterial(material:Dynamic):NodeMaterial {
        if (material.isNodeMaterial) {
            return material;
        }
        
        var type = material.type.replace('Material', 'NodeMaterial');
        
        var nodeMaterial:NodeMaterial = createNodeMaterialFromType(type);
        
        if (nodeMaterial == null) {
            throw new Error('NodeMaterial: Material "${material.type}" is not compatible.');
        }
        
        for (field in Reflect.fields(material)) {
            nodeMaterial[field] = material[field];
        }
        
        return nodeMaterial;
    }
}

class NodeMaterials {
    public static var map:Map<String, Dynamic> = new Map();
    
    public static function addNodeMaterial(type:String, nodeMaterial:Dynamic) {
        if (nodeMaterial == null || ! Std.isOfType(nodeMaterial, Function)) {
            throw new Error('Node material ${type} is not a class');
        }
        
        if (map.exists(type)) {
            trace('Redefinition of node material ${type}');
            return;
        }
        
        map.set(type, nodeMaterial);
        nodeMaterial.type = type;
    }
    
    public static function createNodeMaterialFromType(type:String):NodeMaterial {
        var material:Dynamic = map.get(type);
        
        if (material != null) {
            return new material();
        }
        
        return null;
    }
}

NodeMaterials.addNodeMaterial('NodeMaterial', NodeMaterial);