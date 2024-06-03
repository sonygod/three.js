import three.constants.Mapping;
import three.renderers.webgl.WebGLCubeRenderTarget;

class WebGLCubeMaps {

    private var renderer: Renderer;
    private var cubemaps: Map<Texture, WebGLCubeRenderTarget>;

    public function new(renderer: Renderer) {
        this.renderer = renderer;
        this.cubemaps = new Map<Texture, WebGLCubeRenderTarget>();
    }

    public function mapTextureMapping(texture: Texture, mapping: Int): Texture {
        if (mapping == Mapping.EquirectangularReflectionMapping) {
            texture.mapping = Mapping.CubeReflectionMapping;
        } else if (mapping == Mapping.EquirectangularRefractionMapping) {
            texture.mapping = Mapping.CubeRefractionMapping;
        }
        return texture;
    }

    public function get(texture: Texture): Texture {
        if (texture != null && texture.isTexture) {
            var mapping = texture.mapping;
            if (mapping == Mapping.EquirectangularReflectionMapping || mapping == Mapping.EquirectangularRefractionMapping) {
                if (this.cubemaps.exists(texture)) {
                    var cubemap = this.cubemaps.get(texture).texture;
                    return this.mapTextureMapping(cubemap, texture.mapping);
                } else {
                    var image = texture.image;
                    if (image != null && image.height > 0) {
                        var renderTarget = new WebGLCubeRenderTarget(image.height);
                        renderTarget.fromEquirectangularTexture(this.renderer, texture);
                        this.cubemaps.set(texture, renderTarget);
                        texture.addEventListener('dispose', this.onTextureDispose.bind(this));
                        return this.mapTextureMapping(renderTarget.texture, texture.mapping);
                    } else {
                        // image not yet ready. try the conversion next frame
                        return null;
                    }
                }
            }
        }
        return texture;
    }

    public function onTextureDispose(event: Event) {
        var texture = event.target;
        texture.removeEventListener('dispose', this.onTextureDispose);
        if (this.cubemaps.exists(texture)) {
            var cubemap = this.cubemaps.get(texture);
            this.cubemaps.remove(texture);
            cubemap.dispose();
        }
    }

    public function dispose() {
        this.cubemaps = new Map<Texture, WebGLCubeRenderTarget>();
    }
}