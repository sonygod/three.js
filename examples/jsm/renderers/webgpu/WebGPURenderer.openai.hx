package three.js.examples.jvm.renderers.webgpu;

import three.js.capabilities.WebGPU;
import three.js.common.Renderer;
import three.js.webgl.WebGLBackend;
import three.js.webgpu.WebGPUBackend;

class WebGPURenderer extends Renderer {
    public function new(parameters:Dynamic = {}) {
        var backendClass:Class<Dynamic>;

        if (parameters.forceWebGL) {
            backendClass = WebGLBackend;
        } else if (WebGPU.isAvailable()) {
            backendClass = WebGPUBackend;
        } else {
            backendClass = WebGLBackend;
            trace("THREE.WebGPURenderer: WebGPU is not available, running under WebGL2 backend.");
        }

        var backend = Type.createInstance(backendClass, [parameters]);

        super(backend, parameters);

        isWebGPURenderer = true;
    }
}