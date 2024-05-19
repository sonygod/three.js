package three.js.examples.jmw.renderers.webgl;

import three.js.Lib;
import three.js.renderers.webgl.GLNodeBuilder;
import three.js.renderers.common.Renderer;
import three.js.utils.WebGLAttributeUtils;
import three.js.utils.WebGLState;
import three.js.utils.WebGLUtils;
import three.js.utils.WebGLTextureUtils;
import three.js.utils.WebGLExtensions;
import three.js.utils.WebGLCapabilities;
import three.js.utils.GLFeatureName;
import three.js.renderers.webgl.WebGLBufferRenderer;

class WebGLBackend extends Renderer {
    public var isWebGLBackend:Bool = true;

    public function new(?parameters:Dynamic) {
        super(parameters);
        this.isWebGLBackend = true;
    }

    public function init(renderer:Dynamic) {
        super.init(renderer);
        var parameters = this.parameters;
        var glContext = (parameters.context != null) ? parameters.context : renderer.domElement.getContext('webgl2');
        this.gl = glContext;
        this.extensions = new WebGLExtensions(this);
        this.capabilities = new WebGLCapabilities(this);
        this.attributeUtils = new WebGLAttributeUtils(this);
        this.textureUtils = new WebGLTextureUtils(this);
        this.bufferRenderer = new WebGLBufferRenderer(this);
        this.state = new WebGLState(this);
        this.utils = new WebGLUtils(this);
        this.vaoCache = {};
        this.transformFeedbackCache = {};
        this.discard = false;
        this.trackTimestamp = (parameters.trackTimestamp == true);
        this.extensions.get('EXT_color_buffer_float');
        this.disjoint = this.extensions.get('EXT_disjoint_timer_query_webgl2');
        this.parallel = this.extensions.get('KHR_parallel_shader_compile');
        this._currentContext = null;
    }

    public function get_coordinateSystem():WebGLCoordinateSystem {
        return WebGLCoordinateSystem;
    }

    public function getArrayBufferAsync(attribute:Dynamic):Promise<Dynamic> {
        return this.attributeUtils.getArrayBufferAsync(attribute);
    }

    public function initTimestampQuery(renderContext:Dynamic) {
        if (!this.disjoint || !this.trackTimestamp) return;
        var renderContextData = this.get(renderContext);
        if (this.queryRunning) {
            if (!renderContextData.queryQueue) renderContextData.queryQueue = [];
            renderContextData.queryQueue.push(renderContext);
            return;
        }
        if (renderContextData.activeQuery != null) {
            this.gl.endQuery(this.disjoint.TIME_ELAPSED_EXT);
            renderContextData.activeQuery = null;
        }
        renderContextData.activeQuery = this.gl.createQuery();
        if (renderContextData.activeQuery != null) {
            this.gl.beginQuery(this.disjoint.TIME_ELAPSED_EXT, renderContextData.activeQuery);
            this.queryRunning = true;
        }
    }

    public function prepareTimestampBuffer(renderContext:Dynamic) {
        if (!this.disjoint || !this.trackTimestamp) return;
        var renderContextData = this.get(renderContext);
        if (renderContextData.activeQuery != null) {
            this.gl.endQuery(this.disjoint.TIME_ELAPSED_EXT);
            if (!renderContextData.gpuQueries) renderContextData.gpuQueries = [];
            renderContextData.gpuQueries.push({ query: renderContextData.activeQuery });
            renderContextData.activeQuery = null;
            this.queryRunning = false;
            if (renderContextData.queryQueue != null && renderContextData.queryQueue.length > 0) {
                var nextRenderContext = renderContextData.queryQueue.shift();
                this.initTimestampQuery(nextRenderContext);
            }
        }
    }

    public function resolveTimestampAsync(renderContext:Dynamic, ?type:String = 'render'):Promise<Dynamic> {
        if (!this.disjoint || !this.trackTimestamp) return Promise.resolve(null);
        var renderContextData = this.get(renderContext);
        if (!renderContextData.gpuQueries) renderContextData.gpuQueries = [];
        for (i in 0...renderContextData.gpuQueries.length) {
            var queryInfo = renderContextData.gpuQueries[i];
            var available = this.gl.getQueryParameter(queryInfo.query, this.gl.QUERY_RESULT_AVAILABLE);
            var disjoint = this.gl.getParameter(this.disjoint.GPU_DISJOINT_EXT);
            if (available && !disjoint) {
                var elapsed = this.gl.getQueryParameter(queryInfo.query, this.gl.QUERY_RESULT);
                var duration = Number(elapsed) / 1000000; // Convert nanoseconds to milliseconds
                this.gl.deleteQuery(queryInfo.query);
                renderContextData.gpuQueries.splice(i, 1); // Remove the processed query
                i--;
                this.renderer.info.updateTimestamp(type, duration);
            }
        }
        return Promise.resolve(null);
    }

    public function getContext():Dynamic {
        return this.gl;
    }

    public function beginRender(renderContext:Dynamic) {
        var gl = this.gl;
        var renderContextData = this.get(renderContext);
        this.initTimestampQuery(renderContext);
        renderContextData.previousContext = this._currentContext;
        this._currentContext = renderContext;
        this._setFramebuffer(renderContext);
        this.clear(renderContext.clearColor, renderContext.clearDepth, renderContext.clearStencil, renderContext, false);
        if (renderContext.viewport != null) {
            this.updateViewport(renderContext);
        } else {
            gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
        }
        if (renderContext.scissor != null) {
            var x = renderContext.scissorValue.x;
            var y = renderContext.scissorValue.y;
            var width = renderContext.scissorValue.width;
            var height = renderContext.scissorValue.height;
            gl.scissor(x, y, width, height);
        }
        var occlusionQueryCount = renderContext.occlusionQueryCount;
        if (occlusionQueryCount > 0) {
            renderContextData.currentOcclusionQueries = renderContextData.occlusionQueries;
            renderContextData.currentOcclusionQueryObjects = renderContextData.occlusionQueryObjects;
            renderContextData.lastOcclusionObject = null;
            renderContextData.occlusionQueries = new Array<Dynamic>(occlusionQueryCount);
            renderContextData.occlusionQueryObjects = new Array<Dynamic>(occlusionQueryCount);
            renderContextData.occlusionQueryIndex = 0;
        }
    }

    public function finishRender(renderContext:Dynamic) {
        var gl = this.gl;
        var state = this.state;
        var renderContextData = this.get(renderContext);
        var previousContext = renderContextData.previousContext;
        var textures = renderContext.textures;
        if (textures != null) {
            for (i in 0...textures.length) {
                var texture = textures[i];
                if (texture.generateMipmaps) {
                    this.generateMipmaps(texture);
                }
            }
        }
        this._currentContext = previousContext;
        if (renderContext.textures != null && renderContext.renderTarget != null) {
            var renderTargetContextData = this.get(renderContext.renderTarget);
            var samples = renderContext.renderTarget.samples;
            var fb = renderTargetContextData.framebuffer;
            var mask = gl.COLOR_BUFFER_BIT;
            if (samples > 0) {
                var msaaFrameBuffer = renderTargetContextData.msaaFrameBuffer;
                var textures = renderContext.textures;
                state.bindFramebuffer(gl.READ_FRAMEBUFFER, msaaFrameBuffer);
                state.bindFramebuffer(gl.DRAW_FRAMEBUFFER, fb);
                for (i in 0...textures.length) {
                    gl.blitFramebuffer(0, 0, renderContext.width, renderContext.height, 0, 0, renderContext.width, renderContext.height, mask, gl.NEAREST);
                    gl.invalidateFramebuffer(gl.READ_FRAMEBUFFER, renderTargetContextData.invalidationArray);
                }
            }
        }
        if (previousContext != null) {
            this._setFramebuffer(previousContext);
            if (previousContext.viewport != null) {
                this.updateViewport(previousContext);
            } else {
                gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
            }
        }
        var occlusionQueryCount = renderContext.occlusionQueryCount;
        if (occlusionQueryCount > 0) {
            var renderContextData = this.get(renderContext);
            if (occlusionQueryCount > renderContextData.occlusionQueryIndex) {
                gl.endQuery(gl.ANY_SAMPLES_PASSED);
            }
            this.resolveOccludedAsync(renderContext);
        }
        this.prepareTimestampBuffer(renderContext);
    }

    public function resolveOccludedAsync(renderContext:Dynamic):Promise<Dynamic> {
        var renderContextData = this.get(renderContext);
        var occluded = new WeakSet();
        var gl = this.gl;
        renderContextData.currentOcclusionQueryObjects = null;
        renderContextData.currentOcclusionQueries = null;
        var check = function() {
            var completed = 0;
            for (i in 0...renderContextData.currentOcclusionQueries.length) {
                var query = renderContextData.currentOcclusionQueries[i];
                if (query == null) continue;
                if (gl.getQueryParameter(query, gl.QUERY_RESULT_AVAILABLE)) {
                    if (gl.getQueryParameter(query, gl.QUERY_RESULT) > 0) occluded.add(renderContextData.currentOcclusionQueryObjects[i]);
                    renderContextData.currentOcclusionQueries[i] = null;
                    gl.deleteQuery(query);
                    completed++;
                }
            }
            if (completed < renderContextData.currentOcclusionQueries.length) {
                haxe.Timer.delay(check, 16);
            } else {
                renderContextData.occluded = occluded;
            }
        };
        check();
        return Promise.resolve(null);
    }

    public function isOccluded(renderContext:Dynamic, object:Dynamic):Bool {
        var renderContextData = this.get(renderContext);
        return renderContextData.occluded != null && renderContextData.occluded.has(object);
    }

    public function updateViewport(renderContext:Dynamic) {
        var gl = this.gl;
        var x = renderContext.viewportValue.x;
        var y = renderContext.viewportValue.y;
        var width = renderContext.viewportValue.width;
        var height = renderContext.viewportValue.height;
        gl.viewport(x, y, width, height);
    }

    public function setScissorTest(boolean:Bool) {
        var gl = this.gl;
        if (boolean) {
            gl.enable(gl.SCISSOR_TEST);
        } else {
            gl.disable(gl.SCISSOR_TEST);
        }
    }

    public function clear(color:Bool, depth:Bool, stencil:Bool, descriptor:Dynamic = null, setFrameBuffer:Bool = true) {
        var gl = this.gl;
        if (descriptor == null) {
            descriptor = {
                textures: null,
                clearColorValue: this.getClearColor()
            };
        }
        var clear = 0;
        if (color) clear |= gl.COLOR_BUFFER_BIT;
        if (depth) clear |= gl.DEPTH_BUFFER_BIT;
        if (stencil) clear |= gl.STENCIL_BUFFER_BIT;
        if (clear != 0) {
            var clearColor = descriptor.clearColorValue || this.getClearColor();
            if (depth) this.state.setDepthMask(true);
            if (descriptor.textures == null) {
                gl.clearColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a);
                gl.clear(clear);
            } else {
                if (setFrameBuffer) this._setFramebuffer(descriptor);
                if (color) {
                    for (i in 0...descriptor.textures.length) {
                        gl.clearBufferfv(gl.COLOR, i, [clearColor.r, clearColor.g, clearColor.b, clearColor.a]);
                    }
                }
                if (depth && stencil) {
                    gl.clearBufferfi(gl.DEPTH_STENCIL, 0, 1, 0);
                } else if (depth) {
                    gl.clearBufferfv(gl.DEPTH, 0, [1.0]);
                } else if (stencil) {
                    gl.clearBufferiv(gl.STENCIL, 0, [0]);
                }
            }
        }
    }

    public function beginCompute(computeGroup:Dynamic) {
        var gl = this.gl;
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
        this.initTimestampQuery(computeGroup);
    }
}