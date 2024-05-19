package three.js.src.renderers;

import haxe.ds.ObjectMap;
import openfl.display.GLShader;
import openfl.display.Shader;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.geom.Matrix3D;
import openfl.utils.AgalMiniAssembler;
import three.js.src.core.BufferAttribute;
import three.js.src.core.BufferGeometry;
import three.js.src.core.Camera;
import three.js.src.core.Geometry;
import three.js.src.core.Material;
import three.js.src.core.Mesh;
import three.js.src.core.Object3D;
import three.js.src.core.Program;
import three.js.src.core.RenderState;
import three.js.src.core.Scene;
import three.js.src.core.ShaderMaterial;
import three.js.src.core.Sprite;
import three.js.src.core.Vertex;

class WebGLRenderer {
    // ...

    private var clearColor:Array<Float> = [0, 0, 0, 0];
    private var uintClearColor:Array<UInt> = [0, 0, 0, 0];
    private var intClearColor:Array<Int> = [0, 0, 0, 0];
    private var _gl:Context3D;

    public function new(gl:Context3D) {
        _gl = gl;
    }

    private function clear(?color:Bool = false, ?depth:Bool = false, ?stencil:Bool = false):Void {
        if (color) {
            var r:Float = clearColor[0];
            var g:Float = clearColor[1];
            var b:Float = clearColor[2];
            var a:Float = clearColor[3];

            if (isUnsignedType) {
                uintClearColor[0] = Std.int(r * 255);
                uintClearColor[1] = Std.int(g * 255);
                uintClearColor[2] = Std.int(b * 255);
                uintClearColor[3] = Std.int(a * 255);
                _gl.clearBufferuiv(_gl.COLOR, 0, uintClearColor);
            } else {
                intClearColor[0] = Std.int(r * 255);
                intClearColor[1] = Std.int(g * 255);
                intClearColor[2] = Std.int(b * 255);
                intClearColor[3] = Std.int(a * 255);
                _gl.clearBufferiv(_gl.COLOR, 0, intClearColor);
            }
        } else {
            var bits:Int = 0;
            if (depth) bits |= _gl.DEPTH_BUFFER_BIT;
            if (stencil) {
                bits |= _gl.STENCIL_BUFFER_BIT;
                state.buffers.stencil.setMask(0xFFFFFFFF);
            }
            _gl.clear(bits);
        }
    }

    public function clearColor():Void {
        clear(true, false, false);
    }

    public function clearDepth():Void {
        clear(false, true, false);
    }

    public function clearStencil():Void {
        clear(false, false, true);
    }

    public function dispose():Void {
        canvas.removeEventListener('webglcontextlost', onContextLost, false);
        canvas.removeEventListener('webglcontextrestored', onContextRestore, false);
        canvas.removeEventListener('webglcontextcreationerror', onContextCreationError, false);

        renderLists.dispose();
        renderStates.dispose();
        properties.dispose();
        cubemaps.dispose();
        cubeuvmaps.dispose();
        objects.dispose();
        bindingStates.dispose();
        uniformsGroups.dispose();
        programCache.dispose();

        xr.dispose();

        xr.removeEventListener('sessionstart', onXRSessionStart);
        xr.removeEventListener('sessionend', onXRSessionEnd);

        animation.stop();
    }

    private function onContextLost(event:Event):Void {
        event.preventDefault();
        console.log('THREE.WebGLRenderer: Context Lost.');
        _isContextLost = true;
    }

    private function onContextRestore(?event:Event):Void {
        console.log('THREE.WebGLRenderer: Context Restored.');
        _isContextLost = false;

        var infoAutoReset:Bool = info.autoReset;
        var shadowMapEnabled:Bool = shadowMap.enabled;
        var shadowMapAutoUpdate:Bool = shadowMap.autoUpdate;
        var shadowMapNeedsUpdate:Bool = shadowMap.needsUpdate;
        var shadowMapType:Int = shadowMap.type;

        initGLContext();

        info.autoReset = infoAutoReset;
        shadowMap.enabled = shadowMapEnabled;
        shadowMap.autoUpdate = shadowMapAutoUpdate;
        shadowMap.needsUpdate = shadowMapNeedsUpdate;
        shadowMap.type = shadowMapType;
    }

    private function onContextCreationError(event:Event):Void {
        console.error('THREE.WebGLRenderer: A WebGL context could not be created. Reason: ', event.statusMessage);
    }

    private function onMaterialDispose(event:Event):Void {
        var material:Material = event.target;

        material.removeEventListener('dispose', onMaterialDispose);

        deallocateMaterial(material);
    }

    private function deallocateMaterial(material:Material):Void {
        releaseMaterialProgramReferences(material);

        properties.remove(material);
    }

    private function releaseMaterialProgramReferences(material:Material):Void {
        var programs:Array<Program> = properties.get(material).programs;

        if (programs != null) {
            for (program in programs) {
                programCache.releaseProgram(program);
            }

            if (material.isShaderMaterial) {
                programCache.releaseShaderCache(material);
            }
        }
    }

    public function renderBufferDirect(camera:Camera, scene:Scene, geometry:Geometry, material:Material, object:Object3D, group:Object3D):Void {
        if (scene == null) scene = _emptyScene; // renderBufferDirect second parameter used to be fog (could be null)

        var frontFaceCW:Bool = (object.isMesh && object.matrixWorld.determinant() < 0);

        var program:Program = setProgram(camera, scene, geometry, material, object);

        state.setMaterial(material, frontFaceCW);

        var index:BufferAttribute = geometry.index;
        var rangeFactor:Int = 1;

        if (material.wireframe) {
            index = geometries.getWireframeAttribute(geometry);

            if (index == null) return;

            rangeFactor = 2;
        }

        var drawRange:DrawRange = geometry.drawRange;
        var position:BufferAttribute = geometry.attributes.position;

        var drawStart:Int = drawRange.start * rangeFactor;
        var drawEnd:Int = (drawRange.start + drawRange.count) * rangeFactor;

        if (group != null) {
            drawStart = Math.max(drawStart, group.start * rangeFactor);
            drawEnd = Math.min(drawEnd, (group.start + group.count) * rangeFactor);
        }

        if (index != null) {
            drawStart = Math.max(drawStart, 0);
            drawEnd = Math.min(drawEnd, index.count);
        } else if (position != null) {
            drawStart = Math.max(drawStart, 0);
            drawEnd = Math.min(drawEnd, position.count);
        }

        var drawCount:Int = drawEnd - drawStart;

        if (drawCount < 0 || drawCount == Math.POSITIVE_INFINITY) return;

        bindingStates.setup(object, material, program, geometry, index);

        var attribute:BufferAttribute;
        var renderer:BufferRenderer = bufferRenderer;

        if (index != null) {
            attribute = attributes.get(index);

            renderer = indexedBufferRenderer;
            renderer.setIndex(attribute);
        }

        if (object.isMesh) {
            if (material.wireframe) {
                state.setLineWidth(material.wireframeLinewidth * getTargetPixelRatio());
                renderer.setMode(_gl.LINES);
            } else {
                renderer.setMode(_gl.TRIANGLES);
            }
        } else if (object.isLine) {
            var lineWidth:Float = material.linewidth;

            if (lineWidth == null) lineWidth = 1; // Not using Line*Material

            state.setLineWidth(lineWidth * getTargetPixelRatio());

            if (object.isLineSegments) {
                renderer.setMode(_gl.LINES);
            } else if (object.isLineLoop) {
                renderer.setMode(_gl.LINE_LOOP);
            } else {
                renderer.setMode(_gl.LINE_STRIP);
            }
        } else if (object.isPoints) {
            renderer.setMode(_gl.POINTS);
        } else if (object.isSprite) {
            renderer.setMode(_gl.TRIANGLES);
        }

        if (object.isBatchedMesh) {
            if (object._multiDrawInstances != null) {
                renderer.renderMultiDrawInstances(object._multiDrawStarts, object._multiDrawCounts, object._multiDrawCount, object._multiDrawInstances);
            } else {
                renderer.renderMultiDraw(object._multiDrawStarts, object._multiDrawCounts, object._multiDrawCount);
            }
        } else if (object.isInstancedMesh) {
            renderer.renderInstances(drawStart, drawCount, object.count);
        } else if (geometry.isInstancedBufferGeometry) {
            var maxInstanceCount:Int = geometry._maxInstanceCount != null ? geometry._maxInstanceCount : Math.POSITIVE_INFINITY;
            var instanceCount:Int = Math.min(geometry.instanceCount, maxInstanceCount);

            renderer.renderInstances(drawStart, drawCount, instanceCount);
        } else {
            renderer.render(drawStart, drawCount);
        }
    }

    public function prepareMaterial(material:Material, scene:Scene, object:Object3D):Void {
        if (material.transparent && material.side == DoubleSide && material.forceSinglePass == false) {
            material.side = BackSide;
            material.needsUpdate = true;
            getProgram(material, scene, object);

            material.side = FrontSide;
            material.needsUpdate = true;
            getProgram(material, scene, object);

            material.side = DoubleSide;
        } else {
            getProgram(material, scene, object);
        }
    }

    public function compile(scene:Scene, camera:Camera, targetScene:Scene = null):Set<Material> {
        if (targetScene == null) targetScene = scene;

        currentRenderState = renderStates.get(targetScene);
        currentRenderState.init(camera);

        renderStateStack.push(currentRenderState);

        targetScene.traverseVisible(function(object:Object3D) {
            if (object.isLight && object.layers.test(camera.layers)) {
                currentRenderState.pushLight(object);

                if (object.castShadow) {
                    currentRenderState.pushShadow(object);
                }
            }
        });

        if (scene != targetScene) {
            scene.traverseVisible(function(object:Object3D) {
                if (object.isLight && object.layers.test(camera.layers)) {
                    currentRenderState.pushLight(object);

                    if (object.castShadow) {
                        currentRenderState.pushShadow(object);
                    }
                }
            });
        }

        currentRenderState.setupLights(_useLegacyLights);

        var materials:Set<Material> = new Set();

        scene.traverse(function(object:Object3D) {
            var material:Material = object.material;

            if (material) {
                if (Std.is(material, Array)) {
                    for (material2 in material) {
                        prepareMaterial(material2, targetScene, object);
                        materials.add(material2);
                    }
                } else {
                    prepareMaterial(material, targetScene, object);
                    materials.add(material);
                }
            }
        });

        renderStateStack.pop();
        currentRenderState = null;

        return materials;
    }

    public function compileAsync(scene:Scene, camera:Camera, targetScene:Scene = null):Promise<Scene> {
        var materials:Set<Material> = compile(scene, camera, targetScene);

        return new Promise(function(resolve) {
            function checkMaterialsReady() {
                materials.forEach(function(material) {
                    var materialProperties:Object = properties.get(material);
                    var program:Program = materialProperties.currentProgram;

                    if (program.isReady()) {
                        materials.delete(material);
                    }
                });

                if (materials.size == 0) {
                    resolve(scene);
                    return;
                }

                setTimeout(checkMaterialsReady, 10);
            }

            if (extensions.get('KHR_parallel_shader_compile') != null) {
                checkMaterialsReady();
            } else {
                setTimeout(checkMaterialsReady, 10);
            }
        });
    }
}