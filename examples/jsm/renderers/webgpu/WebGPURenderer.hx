package three.js.examples.jvm.renderers.webgpu;

import three.js.capabilities.WebGPU;
import three.js.renderers.common.Renderer;
import three.js.renderers.webgl.WebGLBackend;
import three.js.renderers.webgpu.WebGPUBackend;

class WebGPURenderer extends Renderer {
    public function new(?parameters:Dynamic) {
        var BackendClass:Class<Dynamic>;

        if (parameters != null && parameters.forceWebGL) {
            BackendClass = WebGLBackend;
        } else if (WebGPU.isAvailable()) {
            BackendClass = WebGPUBackend;
        } else {
            BackendClass = WebGLBackend;
            Console.warn('THREE.WebGPURenderer: WebGPU is not available, running under WebGL2 backend.');
        }

        var backend:Dynamic = Type.createInstance(BackendClass, [parameters]);
        //super(new Proxy(backend, debugHandler));
        super(backend, parameters);
        isWebGPURenderer = true;
    }
}

// Note: The debugHandler is commented out in the original code, so I did not include it in the Haxe conversion.