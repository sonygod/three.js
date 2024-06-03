import DataMap from './DataMap';
import Color4 from './Color4';
import { Mesh, SphereGeometry, BackSide, LinearSRGBColorSpace } from 'three';
import { vec4, context, normalWorld, backgroundBlurriness, backgroundIntensity, NodeMaterial, modelViewProjection } from '../../nodes/Nodes';

class Background extends DataMap {

    private var _clearColor:Color4 = new Color4();
    private var renderer:any;
    private var nodes:any;

    public function new(renderer:any, nodes:any) {
        super();
        this.renderer = renderer;
        this.nodes = nodes;
    }

    public function update(scene:any, renderList:Array<any>, renderContext:any) {
        var renderer = this.renderer;
        var background = this.nodes.getBackgroundNode(scene) || scene.background;

        var forceClear = false;

        if (background == null) {
            renderer._clearColor.getRGB(_clearColor, LinearSRGBColorSpace);
            _clearColor.a = renderer._clearColor.a;
        } else if (background.isColor == true) {
            background.getRGB(_clearColor, LinearSRGBColorSpace);
            _clearColor.a = 1;
            forceClear = true;
        } else if (background.isNode == true) {
            var sceneData = this.get(scene);
            var backgroundNode = background;

            _clearColor.copy(renderer._clearColor);

            var backgroundMesh = sceneData.backgroundMesh;

            if (backgroundMesh == null) {
                var backgroundMeshNode = context(vec4(backgroundNode).mul(backgroundIntensity), {
                    getUV: function() {
                        return normalWorld;
                    },
                    getTextureLevel: function() {
                        return backgroundBlurriness;
                    }
                });

                var viewProj = modelViewProjection();
                viewProj = viewProj.setZ(viewProj.w);

                var nodeMaterial = new NodeMaterial();
                nodeMaterial.side = BackSide;
                nodeMaterial.depthTest = false;
                nodeMaterial.depthWrite = false;
                nodeMaterial.fog = false;
                nodeMaterial.vertexNode = viewProj;
                nodeMaterial.fragmentNode = backgroundMeshNode;

                sceneData.backgroundMeshNode = backgroundMeshNode;
                sceneData.backgroundMesh = backgroundMesh = new Mesh(new SphereGeometry(1, 32, 32), nodeMaterial);
                backgroundMesh.frustumCulled = false;

                backgroundMesh.onBeforeRender = function(renderer, scene, camera) {
                    this.matrixWorld.copyPosition(camera.matrixWorld);
                };
            }

            var backgroundCacheKey = backgroundNode.getCacheKey();

            if (sceneData.backgroundCacheKey != backgroundCacheKey) {
                sceneData.backgroundMeshNode.node = vec4(backgroundNode).mul(backgroundIntensity);
                backgroundMesh.material.needsUpdate = true;
                sceneData.backgroundCacheKey = backgroundCacheKey;
            }

            renderList.unshift(backgroundMesh, backgroundMesh.geometry, backgroundMesh.material, 0, 0, null);
        } else {
            trace('THREE.Renderer: Unsupported background configuration.', background);
        }

        if (renderer.autoClear == true || forceClear == true) {
            _clearColor.multiplyScalar(_clearColor.a);

            var clearColorValue = renderContext.clearColorValue;

            clearColorValue.r = _clearColor.r;
            clearColorValue.g = _clearColor.g;
            clearColorValue.b = _clearColor.b;
            clearColorValue.a = _clearColor.a;

            renderContext.depthClearValue = renderer._clearDepth;
            renderContext.stencilClearValue = renderer._clearStencil;

            renderContext.clearColor = renderer.autoClearColor == true;
            renderContext.clearDepth = renderer.autoClearDepth == true;
            renderContext.clearStencil = renderer.autoClearStencil == true;
        } else {
            renderContext.clearColor = false;
            renderContext.clearDepth = false;
            renderContext.clearStencil = false;
        }
    }
}