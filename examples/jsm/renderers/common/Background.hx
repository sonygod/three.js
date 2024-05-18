package three.js.examples.jsm.renderers.common;

import three.js.DataMap;
import three.js.Color4;
import three.js.Mesh;
import three.js.SphereGeometry;
import three.js.BackSide;
import three.js.LinearSRGBColorSpace;
import nodes.Nodes;

class Background extends DataMap {
    private var renderer:Renderer;
    private var nodes:Nodes;

    public function new(renderer:Renderer, nodes:Nodes) {
        super();
        this.renderer = renderer;
        this.nodes = nodes;
    }

    public function update(scene:Scene, renderList:Array<Dynamic>, renderContext:RenderContext) {
        var _clearColor:Color4 = new Color4();
        var background = nodes.getBackgroundNode(scene) || scene.background;

        var forceClear:Bool = false;

        if (background == null) {
            // no background settings, use clear color configuration from the renderer
            renderer._clearColor.getRGB(_clearColor, LinearSRGBColorSpace);
            _clearColor.a = renderer._clearColor.a;
        } else if (background.isColor) {
            // background is an opaque color
            background.getRGB(_clearColor, LinearSRGBColorSpace);
            _clearColor.a = 1;
            forceClear = true;
        } else if (background.isNode) {
            var sceneData = get(scene);
            var backgroundNode = background;

            _clearColor.copy(renderer._clearColor);

            var backgroundMesh:Mesh;
            if (sceneData.backgroundMesh == null) {
                var backgroundMeshNode = context(vec4(backgroundNode).mul(backgroundIntensity), {
                    getUV: function() return normalWorld,
                    getTextureLevel: function() return backgroundBlurriness
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
            console.error('THREE.Renderer: Unsupported background configuration.', background);
        }

        if (renderer.autoClear || forceClear) {
            _clearColor.multiplyScalar(_clearColor.a);
            renderContext.clearColorValue.r = _clearColor.r;
            renderContext.clearColorValue.g = _clearColor.g;
            renderContext.clearColorValue.b = _clearColor.b;
            renderContext.clearColorValue.a = _clearColor.a;
            renderContext.depthClearValue = renderer._clearDepth;
            renderContext.stencilClearValue = renderer._clearStencil;
            renderContext.clearColor = renderer.autoClearColor;
            renderContext.clearDepth = renderer.autoClearDepth;
            renderContext.clearStencil = renderer.autoClearStencil;
        } else {
            renderContext.clearColor = false;
            renderContext.clearDepth = false;
            renderContext.clearStencil = false;
        }
    }
}