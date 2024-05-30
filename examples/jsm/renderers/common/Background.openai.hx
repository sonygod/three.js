package three.js.examples.jm.renderers.common;

import DataMap;
import Color4;
import three.Mesh;
import three.SphereGeometry;
import three.BackSide;
import three.LinearSRGBColorSpace;
import nodes.Nodes;

class Background extends DataMap {

    var renderer:three.Renderer;
    var nodes:nodes.Nodes;

    public function new(renderer:three.Renderer, nodes:nodes.Nodes) {
        super();

        this.renderer = renderer;
        this.nodes = nodes;
    }

    public function update(scene:Scene, renderList:Array<Any>, renderContext:RenderContext) {
        var background:BackgroundNode = nodes.getBackgroundNode(scene) || scene.background;

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
            var sceneData:Dynamic = get(scene);
            var backgroundNode:BackgroundNode = background;

            _clearColor.copy(renderer._clearColor);

            var backgroundMesh:Mesh = sceneData.backgroundMesh;

            if (backgroundMesh == null) {
                var backgroundMeshNode:Node = context(vec4(backgroundNode).mul(backgroundIntensity), {
                    getUV: function() return normalWorld,
                    getTextureLevel: function() return backgroundBlurriness
                });

                var viewProj:Matrix4 = modelViewProjection();
                viewProj.setZ(viewProj.w);

                var nodeMaterial:NodeMaterial = new NodeMaterial();
                nodeMaterial.side = BackSide;
                nodeMaterial.depthTest = false;
                nodeMaterial.depthWrite = false;
                nodeMaterial.fog = false;
                nodeMaterial.vertexNode = viewProj;
                nodeMaterial.fragmentNode = backgroundMeshNode;

                sceneData.backgroundMeshNode = backgroundMeshNode;
                sceneData.backgroundMesh = backgroundMesh = new Mesh(new SphereGeometry(1, 32, 32), nodeMaterial);
                backgroundMesh.frustumCulled = false;

                backgroundMesh.onBeforeRender = function(renderer:three.Renderer, scene:Scene, camera:Camera) {
                    this.matrixWorld.copyPosition(camera.matrixWorld);
                };
            }

            var backgroundCacheKey:String = backgroundNode.getCacheKey();

            if (sceneData.backgroundCacheKey != backgroundCacheKey) {
                sceneData.backgroundMeshNode.node = vec4(backgroundNode).mul(backgroundIntensity);

                backgroundMesh.material.needsUpdate = true;

                sceneData.backgroundCacheKey = backgroundCacheKey;
            }

            renderList.unshift(backgroundMesh, backgroundMesh.geometry, backgroundMesh.material, 0, 0, null);
        } else {
            trace("THREE.Renderer: Unsupported background configuration.");
        }

        if (renderer.autoClear || forceClear) {
            _clearColor.multiplyScalar(_clearColor.a);

            var clearColorValue:Dynamic = renderContext.clearColorValue;

            clearColorValue.r = _clearColor.r;
            clearColorValue.g = _clearColor.g;
            clearColorValue.b = _clearColor.b;
            clearColorValue.a = _clearColor.a;

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