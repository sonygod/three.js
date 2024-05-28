import js.three.*;

class AnaglyphEffect {
    public var colorMatrixLeft:Matrix3;
    public var colorMatrixRight:Matrix3;
    public var _camera:OrthographicCamera;
    public var _scene:Scene;
    public var _stereo:StereoCamera;
    public var _renderTargetL:WebGLRenderTarget;
    public var _renderTargetR:WebGLRenderTarget;
    public var _material:ShaderMaterial;
    public var _mesh:Mesh;

    public function new(renderer:WebGLRenderer, width:Int, height:Int) {
        this.colorMatrixLeft = new Matrix3([0.456100, -0.0400822, -0.0152161, 0.500484, -0.0378246, -0.0205971, 0.176381, -0.0157589, -0.00546856]);
        this.colorMatrixRight = new Matrix3([-0.0434706, 0.378476, -0.0721527, -0.0879388, 0.73364, -0.112961, -0.00155529, -0.0184503, 1.2264]);
        this._camera = new OrthographicCamera(-1.0, 1.0, 1.0, -1.0, 0.0, 1.0);
        this._scene = new Scene();
        this._stereo = new StereoCamera();
        var _params = {
            'minFilter': LinearFilter,
            'magFilter': NearestFilter,
            'format': RGBAFormat
        };
        this._renderTargetL = new WebGLRenderTarget(width, height, _params);
        this._renderTargetR = new WebGLRenderTarget(width, height, _params);
        var _material = new ShaderMaterial({
            'uniforms': {
                'mapLeft': {'value': _renderTargetL.texture},
                'mapRight': {'value': _renderTargetR.texture},
                'colorMatrixLeft': {'value': this.colorMatrixLeft},
                'colorMatrixRight': {'value': this.colorMatrixRight}
            },
            'vertexShader': #''
                varying vec2 vUv;
                void main() {
                    vUv = vec2( uv.x, uv.y );
                    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
                }
            ''#,
            'fragmentShader': #''
                uniform sampler2D mapLeft;
                uniform sampler2D mapRight;
                varying vec2 vUv;
                uniform mat3 colorMatrixLeft;
                uniform mat3 colorMatrixRight;
                void main() {
                    vec2 uv = vUv;
                    vec4 colorL = texture2D( mapLeft, uv );
                    vec4 colorR = texture2D( mapRight, uv );
                    vec3 color = clamp(
                        colorMatrixLeft * colorL.rgb +
                        colorMatrixRight * colorR.rgb, 0., 1. );
                    gl_FragColor = vec4(
                        color.r, color.g, color.b,
                        max( colorL.a, colorR.a ) );
                    #include <tonemapping_fragment>
                    #include <colorspace_fragment>
                }
            ''#
        });
        this._mesh = new Mesh(new PlaneGeometry(2.0, 2.0), _material);
        this._scene.add(this._mesh);
    }

    public function setSize(width:Int, height:Int):Void {
        var renderer = cast renderer;
        renderer.setSize(width, height);
        var pixelRatio = renderer.getPixelRatio();
        this._renderTargetL.setSize(width * pixelRatio, height * pixelRatio);
        this._renderTargetR.setSize(width * pixelRatio, height * pixelRatio);
    }

    public function render(scene:Scene, camera:Camera):Void {
        var renderer = cast renderer;
        var currentRenderTarget = renderer.getRenderTarget();
        if (scene.matrixWorldAutoUpdate)
            scene.updateMatrixWorld();
        if (camera.parent == null && camera.matrixWorldAutoUpdate)
            camera.updateMatrixWorld();
        this._stereo.update(camera);
        renderer.setRenderTarget(this._renderTargetL);
        renderer.clear();
        renderer.render(scene, this._stereo.cameraL);
        renderer.setRenderTarget(this._renderTargetR);
        renderer.clear();
        renderer.render(scene, this._stereo.cameraR);
        renderer.setRenderTarget(null);
        renderer.render(this._scene, this._camera);
        renderer.setRenderTarget(currentRenderTarget);
    }

    public function dispose():Void {
        this._renderTargetL.dispose();
        this._renderTargetR.dispose();
        this._mesh.geometry.dispose();
        this._mesh.material.dispose();
    }
}

class Export {
    static public function AnaglyphEffect() return AnaglyphEffect;
}