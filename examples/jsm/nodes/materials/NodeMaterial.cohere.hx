import js.NodeUtils;
import js.AttributeNode.attribute;
import js.PropertyNode.{output, diffuseColor, varyingProperty};
import js.MaterialNode.{materialAlphaTest, materialColor, materialOpacity, materialEmissive, materialNormal};
import js.ModelViewProjectionNode.modelViewProjection;
import js.NormalNode.{transformedNormalView, normalLocal};
import js.InstanceNode.instance;
import js.BatchNode.batch;
import js.MaterialReferenceNode.materialReference;
import js.PositionNode.{positionLocal, positionView};
import js.SkinningNode.skinningReference;
import js.MorphNode.morphReference;
import js.TextureNode.{texture, cubeTexture};
import js.LightsNode.lightsNode;
import js.MathNode.mix;
import js.ShaderNode.{float, vec3, vec4};
import js.AONode.AONode;
import js.LightingContextNode.lightingContext;
import js.EnvironmentNode.EnvironmentNode;
import js.IrradianceNode.IrradianceNode;
import js.ViewportDepthNode.depthPixel;
import js.CameraNode.cameraLogDepth;
import js.ClippingNode.{clipping, clippingAlpha};
import js.FrontFacingNode.faceDirection;

class NodeMaterial {
    public isNodeMaterial:Bool;
    public type:String;
    public forceSinglePass:Bool;
    public fog:Bool;
    public lights:Bool;
    public normals:Bool;
    public lightsNode:Dynamic;
    public envNode:Dynamic;
    public aoNode:Dynamic;
    public colorNode:Dynamic;
    public normalNode:Dynamic;
    public opacityNode:Dynamic;
    public backdropNode:Dynamic;
    public backdropAlphaNode:Dynamic;
    public alphaTestNode:Dynamic;
    public positionNode:Dynamic;
    public depthNode:Dynamic;
    public shadowNode:Dynamic;
    public shadowPositionNode:Dynamic;
    public outputNode:Dynamic;
    public fragmentNode:Dynamic;
    public vertexNode:Dynamic;
    public clippingContext:Dynamic;
    public globalClippingCount:Int;
    public localClippingCount:Int;
    public alphaToCoverage:Bool;
    public renderer:Dynamic;
    public object:Dynamic;
    public geometry:Dynamic;
    public displacementMap:Dynamic;
    public displacementScale:Dynamic;
    public displacementBias:Dynamic;
    public mvp:Dynamic;
    public material:Dynamic;
    public emissiveNode:Dynamic;
    public builder:Dynamic;
    public context:Dynamic;
    public resultNode:Dynamic;
    public clippingNode:Dynamic;
    public outgoingLightNode:Dynamic;
    public lightingModel:Dynamic;
    public fogNode:Dynamic;
    public function new() {
        this.isNodeMaterial = true;
        this.type = this.constructor.type;
        this.forceSinglePass = false;
        this.fog = true;
        this.lights = true;
        this.normals = true;
        this.lightsNode = null;
        this.envNode = null;
        this.aoNode = null;
        this.colorNode = null;
        this.normalNode = null;
        this.opacityNode = null;
        this.backdropNode = null;
        this.backdropAlphaNode = null;
        this.alphaTestNode = null;
        this.positionNode = null;
        this.depthNode = null;
        this.shadowNode = null;
        this.shadowPositionNode = null;
        this.outputNode = null;
        this.fragmentNode = null;
        this.vertexNode = null;
    }
    public function customProgramCacheKey():String {
        return this.type + js.NodeUtils.getCacheKey(this);
    }
    public function build(builder:Dynamic) {
        this.setup(builder);
    }
    public function setup(builder:Dynamic) {
        builder.addStack();
        builder.stack.outputNode = this.vertexNode || this.setupPosition(builder);
        builder.addFlow('vertex', builder.removeStack());
        builder.addStack();
        this.resultNode = null;
        this.clippingNode = this.setupClipping(builder);
        if (this.depthWrite) {
            this.setupDepth(builder);
        }
        if (this.fragmentNode == null) {
            if (this.normals) {
                this.setupNormal();
            }
            this.setupDiffuseColor({object: builder.object, geometry: builder.geometry});
            this.setupVariants(builder);
            this.outgoingLightNode = this.setupLighting(builder);
            if (this.clippingNode != null) {
                builder.stack.add(this.clippingNode);
            }
            var basicOutput = vec4(this.outgoingLightNode, diffuseColor.a).max(0);
            this.resultNode = this.setupOutput(builder, basicOutput);
            output.assign(this.resultNode);
            if (this.outputNode != null) {
                this.resultNode = this.outputNode;
            }
        } else {
            var fragmentNode = this.fragmentNode;
            if (!fragmentNode.isOutputStructNode) {
                fragmentNode = vec4(fragmentNode);
            }
            this.resultNode = this.setupOutput(builder, fragmentNode);
        }
        builder.stack.outputNode = this.resultNode;
        builder.addFlow('fragment', builder.removeStack());
    }
    public function setupClipping(builder:Dynamic):Dynamic {
        if (builder.clippingContext == null) {
            return null;
        }
        var result = null;
        if (builder.clippingContext.globalClippingCount > 0 || builder.clippingContext.localClippingCount > 0) {
            if (this.alphaToCoverage) {
                result = clippingAlpha();
            } else {
                builder.stack.add(clipping());
            }
        }
        return result;
    }
    public function setupDepth(builder:Dynamic) {
        var renderer = builder.renderer;
        if (renderer.logarithmicDepthBuffer) {
            var fragDepth = modelViewProjection().w.add(1);
            this.depthNode = fragDepth.log2().mul(cameraLogDepth).mul(0.5);
        }
        if (this.depthNode != null) {
            depthPixel.assign(this.depthNode).append();
        }
    }
    public function setupPosition(builder:Dynamic):Dynamic {
        var object = builder.object;
        var geometry = object.geometry;
        builder.addStack();
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
            positionLocal.addAssign(normalLocal.normalize().mul(displacementMap.x.mul(displacementScale).add(displacementBias)));
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
        this.mvp = modelViewProjection();
        builder.context.vertex = builder.removeStack();
        builder.context.mvp = this.mvp;
        return this.mvp;
    }
    public function setupDiffuseColor(params:Dynamic):Void {
        var colorNode = this.colorNode ? vec4(this.colorNode) : materialColor;
        if (this.vertexColors && geometry.hasAttribute('color')) {
            colorNode = vec4(colorNode.xyz.mul(attribute('color', 'vec3')), colorNode.a);
        }
        if (object.instanceColor) {
            var instanceColor = varyingProperty('vec3', 'vInstanceColor');
            colorNode = instanceColor.mul(colorNode);
        }
        diffuseColor.assign(colorNode);
        var opacityNode = this.opacityNode ? float(this.opacityNode) : materialOpacity;
        diffuseColor.a.assign(diffuseColor.a.mul(opacityNode));
        if (this.alphaTestNode != null || this.alphaTest > 0) {
            var alphaTestNode = this.alphaTestNode != null ? float(this.alphaTestNode) : materialAlphaTest;
            diffuseColor.a.lessThanEqual(alphaTestNode).discard();
        }
    }
    public function setupVariants(builder:Dynamic):Void {
        // Interface function.
    }
    public function setupNormal():Void {
        if (this.flatShading) {
            var normalNode = positionView.dFdx().cross(positionView.dFdy()).normalize();
            transformedNormalView.assign(normalNode.mul(faceDirection));
        } else {
            var normalNode = this.normalNode ? vec3(this.normalNode) : materialNormal;
            transformedNormalView.assign(normalNode.mul(faceDirection));
        }
    }
    public function getEnvNode(builder:Dynamic):Dynamic {
        var node = null;
        if (this.envNode) {
            node = this.envNode;
        } else if (this.envMap) {
            node = this.envMap.isCubeTexture ? cubeTexture(this.envMap) : texture(this.envMap);
        } else if (builder.environmentNode) {
            node = builder.environmentNode;
        }
        return node;
    }
    public function setupLights(builder:Dynamic):Dynamic {
        var envNode = this.getEnvNode(builder);
        var materialLightsNode = [];
        if (envNode) {
            materialLightsNode.push(new EnvironmentNode(envNode));
        }
        if (builder.material.lightMap) {
            materialLightsNode.push(new IrradianceNode(materialReference('lightMap', 'texture')));
        }
        if (this.aoNode != null || builder.material.aoMap) {
            var aoNode = this.aoNode != null ? this.aoNode : texture(builder.material.aoMap);
            materialLightsNode.push(new AONode(aoNode));
        }
        var lightsN = this.lightsNode || builder.lightsNode;
        if (materialLightsNode.length > 0) {
            lightsN = lightsNode([...lightsN.lightNodes, ...materialLightsNode]);
        }
        return lightsN;
    }
    public function setupLightingModel(builder:Dynamic):Void {
        // Interface function.
    }
    public function setupLighting(builder:Dynamic):Dynamic {
        var material = builder.material;
        var outgoingLightNode = diffuseColor.rgb;
        if (this.lights || this.lightsNode != null) {
            var lightsNode = this.setupLights(builder);
            if (lightsNode && lightsNode.hasLight) {
                this.lightingModel = this.setupLightingModel(builder);
                outgoingLightNode = lightingContext(lightsNode, this.lightingModel, this.backdropNode, this.backdropAlphaNode);
            }
        } else if (this.backdropNode != null) {
            outgoingLightNode = vec3(this.backdropAlphaNode != null ? mix(outgoingLightNode, this.backdropNode, this.backdropAlphaNode) : this.backdropNode);
        }
        if (this.emissiveNode && this.emissiveNode.isNode || material.emissive && material.emissive.isColor) {
            outgoingLightNode = outgoingLightNode.add(vec3(this.emissiveNode ? this.emissiveNode : materialEmissive));
        }
        return outgoingLightNode;
    }
    public function setupOutput(builder:Dynamic, outputNode:Dynamic):Dynamic {
        var fogNode = builder.fogNode;
        if (fogNode) {
            outputNode = vec4(fogNode.mix(outputNode.rgb, fogNode.colorNode), outputNode.a);
        }
        return outputNode;
    }
    public function setDefaultValues(material:Dynamic):Void {
        for (property in material) {
            var value = material[property];
            if (this[property] == null) {
                this[property] = value;
                if (value && value.clone) {
                    this[property] = value.clone();
                }
            }
        }
        var descriptors = Object.getOwnPropertyDescriptors(material.constructor.prototype);
        for (key in descriptors) {
            if (Object.getOwnPropertyDescriptor(this.constructor.prototype, key) == null && descriptors[key].get != null) {
                Object.defineProperty(this.constructor.prototype, key, descriptors[key]);
            }
        }
    }
    public function toJSON(meta:Dynamic):Dynamic {
        var isRoot = meta == null || typeof meta == 'string';
        if (isRoot) {
            meta = {
                textures: {},
                images: {},
                nodes: {}
            };
        }
        var data = Material.prototype.toJSON.call(this, meta);
        var nodeChildren = js.NodeUtils.getNodeChildren(this);
        data.inputNodes = {};
        for ({property, childNode} in nodeChildren) {
            data.inputNodes[property] = childNode.toJSON(meta).uuid;
        }
        if (isRoot) {
            var textures = Reflect.field(meta, 'textures');
            var images = Reflect.field(meta, 'images');
            var nodes = Reflect.field(meta, 'nodes');
            if (textures.length > 0) {
                data.textures = textures;
            }
            if (images.length > 0) {
                data.images = images;
            }
            if (nodes.length > 0) {
                data.nodes = nodes;
            }
        }
        return data;
    }
    public function copy(source:Dynamic):Void {
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
        super.copy(source);
    }
    public static function fromMaterial(material:Dynamic):Dynamic {
        if (material.isNodeMaterial) {
            return material;
        }
        var type = material.type.replace('Material', 'NodeMaterial');
        var nodeMaterial = createNodeMaterialFromType(type);
        if (nodeMaterial == null) {
            throw new Error('NodeMaterial: Material "' + material.type + '" is not compatible.');
        }
        for (property in material) {
            nodeMaterial[property] = material[property];
        }
        return nodeMaterial;
    }
}

function addNodeMaterial(type:String, nodeMaterial:Dynamic):Void {
    if (!Std.is(nodeMaterial, Dynamic) || !type) {
        throw new Error('Node material ' + type + ' is not a class');
    }
    if (Reflect.field(NodeMaterials, type)) {
        trace('Redefinition of node material ' + type);
        return;
    }
    Reflect.setField(NodeMaterials, type, nodeMaterial);
    nodeMaterial.type = type;
}

function createNodeMaterialFromType(type:String):Dynamic {
    var Material = Reflect.field(NodeMaterials, type);
    if (Material != null) {
        return new Material();
    }
}

addNodeMaterial('NodeMaterial', NodeMaterial);