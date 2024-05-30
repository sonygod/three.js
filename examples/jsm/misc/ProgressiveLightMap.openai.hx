import three.js.lib.Three;

class ProgressiveLightMap {
    private var renderer:Three.WebGLRenderer;
    private var res:Int;
    private var lightMapContainers:Array<{basicMat:Three.Material, object:Three.Object3D}>;
    private var compiled:Bool;
    private var scene:Three.Scene;
    private var tinyTarget:Three.WebGLRenderTarget;
    private var buffer1Active:Bool;
    private var firstUpdate:Bool;
    private var warned:Bool;
    private var progressiveLightMap1:Three.WebGLRenderTarget;
    private var progressiveLightMap2:Three.WebGLRenderTarget;
    private var uvMat:Three.MeshPhongMaterial;
    private var blurringPlane:Three.Mesh;
    private var labelMesh:Three.Mesh;
    private var labelMaterial:Three.MeshBasicMaterial;

    public function new(renderer:Three.WebGLRenderer, res:Int = 1024) {
        this.renderer = renderer;
        this.res = res;
        this.lightMapContainers = [];
        this.compiled = false;
        this.scene = new Three.Scene();
        this.scene.background = null;
        this.tinyTarget = new Three.WebGLRenderTarget(1, 1);
        this.buffer1Active = false;
        this.firstUpdate = true;
        this.warned = false;

        // Create the Progressive LightMap Texture
        var format:Three.TextureFormat = ~/Android|iPad|iPhone|iPod/.test(navigator.userAgent) ? Three.HalfFloatType : Three.FloatType;
        this.progressiveLightMap1 = new Three.WebGLRenderTarget(res, res, {type: format});
        this.progressiveLightMap2 = new Three.WebGLRenderTarget(res, res, {type: format});
        this.progressiveLightMap2.texture.channel = 1;

        // Inject some spicy new logic into a standard phong material
        this.uvMat = new Three.MeshPhongMaterial();
        this.uvMat.uniforms = {};
        this.uvMat.onBeforeCompile = function(shader) {
            // Vertex Shader: Set Vertex Positions to the Unwrapped UV Positions
            shader.vertexShader =
                '#define USE_LIGHTMAP\n#define LIGHTMAP_UV uv1\n' +
                shader.vertexShader.slice(0, -1) +
                '    gl_Position = vec4((LIGHTMAP_UV - 0.5) * 2.0, 1.0, 1.0); }';

            // Fragment Shader: Set Pixels to average in the Previous frame's Shadows
            var bodyStart = shader.fragmentShader.indexOf('void main() {');
            shader.fragmentShader =
                '#define USE_LIGHTMAP\n' +
                shader.fragmentShader.slice(0, bodyStart) +
                '    uniform sampler2D previousShadowMap;\nuniform float averagingWindow;\n' +
                shader.fragmentShader.slice(bodyStart - 1, -1) +
                'vec3 texelOld = texture2D(previousShadowMap, vLightMapUv).rgb;\n    gl_FragColor.rgb = mix(texelOld, gl_FragColor.rgb, 1.0/averagingWindow);';

            // Set the Previous Frame's Texture Buffer and Averaging Window
            shader.uniforms.previousShadowMap = {value: this.progressiveLightMap1.texture};
            shader.uniforms.averagingWindow = {value: 100};

            this.uvMat.uniforms = shader.uniforms;

            // Set the new Shader to this
            this.uvMat.userData.shader = shader;

            this.compiled = true;
        };
    }

    /**
     * Sets these objects' materials' lightmaps and modifies their uv1's.
     * @param objects An array of objects and lights to set up your lightmap.
     */
    public function addObjectsToLightMap(objects:Array<Three.Object3D>) {
        // Prepare list of UV bounding boxes for packing later...
        this.uv_boxes = []; var padding = 3 / this.res;

        for (ob in objects) {
            var object = ob;

            // If this object is a light, simply add it to the internal scene
            if (object.isLight) {
                this.scene.attach(object);
                continue;
            }

            if (!object.geometry.hasAttribute('uv')) {
                console.warn('All lightmap objects need UVs!');
                continue;
            }

            if (this.blurringPlane == null) {
                this._initializeBlurPlane(this.res, this.progressiveLightMap1);
            }

            // Apply the lightmap to the object
            object.material.lightMap = this.progressiveLightMap2.texture;
            object.material.dithering = true;
            object.castShadow = true;
            object.receiveShadow = true;
            object.renderOrder = 1000 + objects.indexOf(object);

            // Prepare UV boxes for potpack
            // TODO: Size these by object surface area
            this.uv_boxes.push({w: 1 + (padding * 2), h: 1 + (padding * 2), index: objects.indexOf(object)});

            this.lightMapContainers.push({basicMat: object.material, object: object});

            this.compiled = false;
        }

        // Pack the objects' lightmap UVs into the same global space
        var dimensions = potpack(this.uv_boxes);
        this.uv_boxes.forEach(function(box) {
            var uv1 = objects[box.index].geometry.getAttribute('uv').clone();
            for (i in 0...uv1.array.length) {
                uv1.array[i] = (uv1.array[i] + box.x + padding) / dimensions.w;
                uv1.array[i + 1] = (uv1.array[i + 1] + box.y + padding) / dimensions.h;
            }

            objects[box.index].geometry.setAttribute('uv1', uv1);
            objects[box.index].geometry.getAttribute('uv1').needsUpdate = true;
        });
    }

    /**
     * This function renders each mesh one at a time into their respective surface maps
     * @param camera Standard Rendering Camera
     * @param blendWindow When >1, samples will accumulate over time.
     * @param blurEdges  Whether to fix UV Edges via blurring
     */
    public function update(camera:Three.Camera, blendWindow:Int = 100, blurEdges:Bool = true) {
        if (this.blurringPlane == null) {
            return;
        }

        // Store the original Render Target
        var oldTarget = this.renderer.getRenderTarget();

        // The blurring plane applies blur to the seams of the lightmap
        this.blurringPlane.visible = blurEdges;

        // Steal the Object3D from the real world to our special dimension
        for (l in this.lightMapContainers) {
            l.object.oldScene = l.object.parent;
            this.scene.attach(l.object);
        }

        // Render once normally to initialize everything
        if (this.firstUpdate) {
            this.renderer.setRenderTarget(this.tinyTarget); // Tiny for Speed
            this.renderer.render(this.scene, camera);
            this.firstUpdate = false;
        }

        // Set each object's material to the UV Unwrapped Surface Mapping Version
        for (l in this.lightMapContainers) {
            this.uvMat.uniforms.averagingWindow = {value: blendWindow};
            l.object.material = this.uvMat;
            l.object.oldFrustumCulled = l.object.frustumCulled;
            l.object.frustumCulled = false;
        }

        // Ping-pong two surface buffers for reading/writing
        var activeMap = this.buffer1Active ? this.progressiveLightMap1 : this.progressiveLightMap2;
        var inactiveMap = this.buffer1Active ? this.progressiveLightMap2 : this.progressiveLightMap1;

        // Render the object's surface maps
        this.renderer.setRenderTarget(activeMap);
        this.uvMat.uniforms.previousShadowMap = {value: inactiveMap.texture};
        this.blurringPlane.material.uniforms.previousShadowMap = {value: inactiveMap.texture};
        this.buffer1Active = !this.buffer1Active;
        this.renderer.render(this.scene, camera);

        // Restore the object's Real-time Material and add it back to the original world
        for (l in this.lightMapContainers) {
            l.object.frustumCulled = l.object.oldFrustumCulled;
            l.object.material = l.basicMat;
            l.object.oldScene.attach(l.object);
        }

        // Restore the original Render Target
        this.renderer.setRenderTarget(oldTarget);
    }

    /**
     * INTERNAL Creates the Blurring Plane
     * @param res The square resolution of this object's lightMap.
     * @param lightMap The lightmap to initialize the plane with.
     */
    private function _initializeBlurPlane(res:Int, lightMap:Three.WebGLRenderTarget) {
        var blurMaterial = new Three.MeshBasicMaterial();
        blurMaterial.uniforms = {previousShadowMap: {value: null}, pixelOffset: {value: 1.0 / res}, polygonOffset: true, polygonOffsetFactor: -1, polygonOffsetUnits: 3.0};
        blurMaterial.onBeforeCompile = function(shader) {
            // Vertex Shader: Set Vertex Positions to the Unwrapped UV Positions
            shader.vertexShader =
                '#define USE_UV\n' +
                shader.vertexShader.slice(0, -1) +
                '    gl_Position = vec4((uv - 0.5) * 2.0, 1.0, 1.0); }';

            // Fragment Shader: Set Pixels to 9-tap box blur the current frame's Shadows
            var bodyStart = shader.fragmentShader.indexOf('void main() {');
            shader.fragmentShader =
                '#define USE_UV\n' +
                shader.fragmentShader.slice(0, bodyStart) +
                '    uniform sampler2D previousShadowMap;\nuniform float pixelOffset;\n' +
                shader.fragmentShader.slice(bodyStart - 1, -1) +
                '    gl_FragColor.rgb = (' +
                '        texture2D(previousShadowMap, vUv + vec2(pixelOffset, 0.0)).rgb + ' +
                '        texture2D(previousShadowMap, vUv + vec2(0.0, pixelOffset)).rgb + ' +
                '        texture2D(previousShadowMap, vUv + vec2(0.0, -pixelOffset)).rgb + ' +
                '        texture2D(previousShadowMap, vUv + vec2(-pixelOffset, 0.0)).rgb + ' +
                '        texture2D(previousShadowMap, vUv + vec2(pixelOffset, pixelOffset)).rgb + ' +
                '        texture2D(previousShadowMap, vUv + vec2(-pixelOffset, pixelOffset)).rgb + ' +
                '        texture2D(previousShadowMap, vUv + vec2(pixelOffset, -pixelOffset)).rgb + ' +
                '        texture2D(previousShadowMap, vUv + vec2(-pixelOffset, -pixelOffset)).rgb)/8.0;';

            // Set the LightMap Accumulation Buffer
            shader.uniforms.previousShadowMap = {value: lightMap.texture};
            shader.uniforms.pixelOffset = {value: 0.5 / res};
            blurMaterial.uniforms = shader.uniforms;

            // Set the new Shader to this
            blurMaterial.userData.shader = shader;

            this.compiled = true;
        };

        this.blurringPlane = new Three Mesh(new Three.PlaneGeometry(1, 1), blurMaterial);
        this.blurringPlane.name = 'Blurring Plane';
        this.blurringPlane.frustumCulled = false;
        this.blurringPlane.renderOrder = 0;
        this.blurringPlane.material.depthWrite = false;
        this.scene.add(this.blurringPlane);
    }

    public function showDebugLightmap(visible:Bool, position:Three.Vector3 = null) {
        if (this.lightMapContainers.length == 0) {
            if (!this.warned) {
                console.warn('Call this after adding the objects!');
                this.warned = true;
            }

            return;
        }

        if (this.labelMesh == null) {
            this.labelMaterial = new Three.MeshBasicMaterial({map: this.progressiveLightMap1.texture, side: Three.DoubleSide});
            this.labelPlane = new Three.PlaneGeometry(100, 100);
            this.labelMesh = new Three.Mesh(this.labelPlane, this.labelMaterial);
            this.labelMesh.position.y = 250;
            this.lightMapContainers[0].object.parent.add(this.labelMesh);
        }

        if (position != null) {
            this.labelMesh.position.copy(position);
        }

        this.labelMesh.visible = visible;
    }
}