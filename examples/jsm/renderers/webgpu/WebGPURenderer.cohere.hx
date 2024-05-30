import WebGPU from "../../capabilities/WebGPU.hx";
import Renderer from "../common/Renderer.hx";
import WebGLBackend from "../webgl/WebGLBackend.hx";
import WebGPUBackend from "./WebGPUBackend.hx";

class WebGPURenderer extends Renderer {
    public isWebGPURenderer:Bool;
    public function new(parameters:Dynamic = {}) {
        var BackendClass:Class<?>;
        if (parameters.forceWebGL) {
            BackendClass = WebGLBackend;
        } else if (WebGPU.isAvailable()) {
            BackendClass = WebGPUBackend;
        } else {
            BackendClass = WebGLBackend;
            trace("THREE.WebGPURenderer: WebGPU is not available, running under WebGL2 backend.", Sys.stderr);
        }

        var backend = BackendClass.construct(parameters);
        super(backend, parameters);
        this.isWebGPURenderer = true;
    }
}