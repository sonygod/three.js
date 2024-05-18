Here is the converted Haxe code:
```
package three.js.examples.javascript.misc;

import three.js.*;

class ProgressiveLightMap {
    public var renderer:WebGLRenderer;
    public var res:Int;
    public var lightMapContainers:Array<{basicMat:MeshPhongMaterial, object:Object3D}> = [];
    public var compiled:Bool = false;
    public var scene:Scene;
    public var tinyTarget:WebGLRenderTarget;
    public var buffer1Active:Bool = false;
    public var firstUpdate:Bool = true;
    public var warned:Bool = false;
    public var progressiveLightMap1:WebGLRenderTarget;
    public var progressiveLightMap2:WebGLRenderTarget;
    public var uvMat:MeshPhongMaterial;
    public var blurringPlane:Mesh;
    public var labelMesh:Mesh;
    public var labelMaterial:MeshBasicMaterial;

    public function new(renderer:WebGLRenderer, res:Int = 1024) {
        this.renderer = renderer;
        this.res = res;
        this.scene = new Scene();
        this.scene.background = null;
        this.tinyTarget = new WebGLRenderTarget(1, 1);
        this.buffer1Active = false;
        this.firstUpdate = true;
        this.warned = false;

        // Create the Progressive LightMap Texture
        var format:TextureFormat = ~/Android|iPad|iPhone|iPod/.test(navigator.userAgent) ? HalfFloatType : FloatType;
        this.progressiveLightMap1 = new WebGLRenderTarget(res, res, { type: format });
        this.progressiveLightMap2 = new WebGLRenderTarget(res, res, { type: format });
        this.progressiveLightMap2.texture.channel = 1;

        // Inject some spicy new logic into a standard phong material
        this.uvMat = new MeshPhongMaterial();
        this.uvMat.uniforms = {};
        this.uvMat.onBeforeCompile = function(shader:Shader) {
            // Vertex Shader: Set Vertex Positions to the Unwrapped UV Positions
            shader.vertexShader =
                '
                attribute vec2 uv1;
                #define USE_LIGHTMAP
                #define LIGHTMAP_UV uv1
                ' + shader.vertexShader.slice(0, -1) +
                ' gl_Position = vec4((LIGHTMAP_UV - 0.5) * 2.0, 1.0, 1.0); }';

            // Fragment Shader: Set Pixels to average in the Previous frame's Shadows
            var bodyStart:Int = shader.fragmentShader.indexOf('void main() {');
            shader.fragmentShader =
                '#define USE_LIGHTMAP\n' +
                shader.fragmentShader.slice(0, bodyStart) +
                ' uniform sampler2D previousShadowMap;\n uniform float averagingWindow;\n' +
                shader.fragmentShader.slice(bodyStart - 1, -1) +
                '
                vec3 texelOld = texture2D(previousShadowMap, vLightMapUv).rgb;
                gl_FragColor.rgb = mix(texelOld, gl_FragColor.rgb, 1.0/averagingWindow);
            ';

            // Set the Previous Frame's Texture Buffer and Averaging Window
            shader.uniforms.previousShadowMap = { value: this.progressiveLightMap1.texture };
            shader.uniforms.averagingWindow = { value: 100 };

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
    public function addObjectsToLightMap(objects:Array<Object3D>) {
        // Prepare list of UV bounding boxes for packing later...
        this.uv_boxes = []; var padding:Float = 3 / this.res;

        for (i in 0...objects.length) {
            var object:Object3D = objects[i];

            // If this object is a light, simply add it to the internal scene
            if (object.isLight) {
                this.scene.attach(object); continue;
            }

            if (!object.geometry.hasAttribute('uv')) {
                console.warn('All lightmap objects need UVs!'); continue;
            }

            if (this.blurringPlane == null) {
                this._initializeBlurPlane(this.res, this.progressiveLightMap1);
            }

            // Apply the lightmap to the object
            object.material.lightMap = this.progressiveLightMap2.texture;
            object.material.dithering = true;
            object.castShadow = true;
            object.receiveShadow = true;
            object.renderOrder = 1000 + i;

            // Prepare UV boxes for potpack
            // TODO: Size these by object surface area
            this.uv_boxes.push({ w: 1 + (padding * 2), h: 1 + (padding * 2), index: i });

            this.lightMapContainers.push({ basicMat: object.material, object: object });

            this.compiled = false;
        }

        // Pack the objects' lightmap UVs into the same global space
        var dimensions:Dynamic = potpack(this.uv_boxes);
        for (box in this.uv_boxes) {
            var uv1:GeometryAttribute = objects[box.index].geometry.getAttribute('uv').clone();
            for (i in 0...uv1.array.length) {
                uv1.array[i] = (uv1.array[i] + box.x + padding) / dimensions.w;
                uv1.array[i + 1] = (uv1.array[i + 1] + box.y + padding) / dimensions.h;
            }

            objects[box.index].geometry.setAttribute('uv1', uv1);
            objects[box.index].geometry.getAttribute('uv1').needsUpdate = true;
        }
    }

    /**
     * This function renders each mesh one at a time into their respective surface maps
     * @param camera Standard Rendering Camera
     * @param blendWindow When >1, samples will accumulate over time.
     * @param blurEdges  Whether to fix UV Edges via blurring
     */
    public function update(camera:Camera, blendWindow:Int = 100, blurEdges:Bool = true) {
        if (this.blurringPlane == null) {
            return;
        }

        // Store the original Render Target
        var oldTarget:WebGLRenderTarget = this.renderer.getRenderTarget();

        // The blurring plane applies blur to the seams of the lightmap
        this.blurringPlane.visible = blurEdges;

        // Steal the Object3D from the real world to our special dimension
        for (l in 0...this.lightMapContainers.length) {
            this.lightMapContainers[l].object.oldScene = this.lightMapContainers[l].object.parent;
            this.scene.attach(this.lightMapContainers[l].object);
        }

        // Render once normally to initialize everything
        if (this.firstUpdate) {
            this.renderer.setRenderTarget(this.tinyTarget); // Tiny for Speed
            this.renderer.render(this.scene, camera);
            this.firstUpdate = false;
        }

        // Set each object's material to the UV Unwrapped Surface Mapping Version
        for (l in 0...this.lightMapContainers.length) {
            this.uvMat.uniforms.averagingWindow = { value: blendWindow };
            this.lightMapContainers[l].object.material = this.uvMat;
            this.lightMapContainers[l].object.oldFrustumCulled = this.lightMapContainers[l].object.frustumCulled;
            this.lightMapContainers[l].object.frustumCulled = false;
        }

        // Ping-pong two surface buffers for reading/writing
        var activeMap:WebGLRenderTarget = this.buffer1Active ? this.progressiveLightMap1 : this.progressiveLightMap2;
        var inactiveMap:WebGLRenderTarget = this.buffer1Active ? this.progressiveLightMap2 : this.progressiveLightMap1;

        // Render the object's surface maps
        this.renderer.setRenderTarget(activeMap);
        this.uvMat.uniforms.previousShadowMap = { value: inactiveMap.texture };
        this.blurringPlane.material.uniforms.previousShadowMap = { value: inactiveMap.texture };
        this.buffer1Active = !this.buffer1Active;
        this.renderer.render(this.scene, camera);

        // Restore the object's Real-time Material and add it back to the original world
        for (l in 0...this.lightMapContainers.length) {
            this.lightMapContainers[l].object.frustumCulled = this.lightMapContainers[l].object.oldFrustumCulled;
            this.lightMapContainers[l].object.material = this.lightMapContainers[l].basicMat;
            this.lightMapContainers[l].object.oldScene.attach(this.lightMapContainers[l].object);
        }

        // Restore the original Render Target
        this.renderer.setRenderTarget(oldTarget);
    }

    /**
     * DEBUG
     * Draw the lightmap in the main scene.  Call this after adding the objects to it.
     * @param visible Whether the debug plane should be visible
     * @param position Where the debug plane should be drawn
     */
    public function showDebugLightmap(visible:Bool, ?position:Vector3) {
        if (this.lightMapContainers.length == 0) {
            if (!this.warned) {
                console.warn('Call this after adding the objects!');
                this.warned = true;
            }

            return;
        }

        if (this.labelMesh == null) {
            this.labelMaterial = new MeshBasicMaterial({ map: this.progressiveLightMap1.texture, side: DoubleSide });
            this.labelPlane = new PlaneGeometry(100, 100);
            this.labelMesh = new Mesh(this.labelPlane, this.labelMaterial);
            this.labelMesh.position.y = 250;
            this.lightMapContainers[0].object.parent.add(this.labelMesh);
        }

        if (position != null) {
            this.labelMesh.position.copy(position);
        }

        this.labelMesh.visible = visible;
    }

    /**
     * INTERNAL Creates the Blurring Plane
     * @param res The square resolution of this object's lightMap.
     * @param lightMap The lightmap to initialize the plane with.
     */
    private function _initializeBlurPlane(res:Int, lightMap:WebGLRenderTarget) {
        var blurMaterial:MeshBasicMaterial = new MeshBasicMaterial();
        blurMaterial.uniforms = { previousShadowMap: { value: null }, pixelOffset: { value: 1.0 / res }, polygonOffset: true, polygonOffsetFactor: -1, polygonOffsetUnits: 3.0 };
        blurMaterial.onBeforeCompile = function(shader:Shader) {
            // Vertex Shader: Set Vertex Positions to the Unwrapped UV Positions
            shader.vertexShader =
                '
                #define USE_UV
                ' + shader.vertexShader.slice(0, -1) +
                ' gl_Position = vec4((uv - 0.5) * 2.0, 1.0, 1.0); }';

            // Fragment Shader: Set Pixels to 9-tap box blur the current frame's Shadows
            var bodyStart:Int = shader.fragmentShader.indexOf('void main() {');
            shader.fragmentShader =
                '#define USE_UV\n' +
                shader.fragmentShader.slice(0, bodyStart) +
                ' uniform sampler2D previousShadowMap;\n uniform float pixelOffset;\n' +
                shader.fragmentShader.slice(bodyStart - 1, -1) +
                '
                gl_FragColor.rgb = (
                                    texture2D(previousShadowMap, vUv + vec2(pixelOffset, 0.0)).rgb +
                                    texture2D(previousShadowMap, vUv + vec2(0.0, pixelOffset)).rgb +
                                    texture2D(previousShadowMap, vUv + vec2(0.0, -pixelOffset)).rgb +
                                    texture2D(previousShadowMap, vUv + vec2(-pixelOffset, 0.0)).rgb +
                                    texture2D(previousShadowMap, vUv + vec2(pixelOffset, pixelOffset)).rgb +
                                    texture2D(previousShadowMap, vUv + vec2(-pixelOffset, pixelOffset)).rgb +
                                    texture2D(previousShadowMap, vUv + vec2(pixelOffset, -pixelOffset)).rgb +
                                    texture2D(previousShadowMap, vUv + vec2(-pixelOffset, -pixelOffset)).rgb)/8.0;
            ';

            // Set the LightMap Accumulation Buffer
            shader.uniforms.previousShadowMap = { value: lightMap.texture };
            shader.uniforms.pixelOffset = { value: 0.5 / res };
            blurMaterial.uniforms = shader.uniforms;

            // Set the new Shader to this
            blurMaterial.userData.shader = shader;
        };

        this.blurringPlane = new Mesh(new PlaneGeometry(1, 1), blurMaterial);
        this.blurringPlane.name = 'Blurring Plane';
        this.blurringPlane.frustumCulled = false;
        this.blurringPlane.renderOrder = 0;
        this.blurringPlane.material.depthWrite = false;
        this.scene.add(this.blurringPlane);
    }
}
```
Note that I've used the `three.js` library for Haxe, which provides the same API as the JavaScript version. You may need to adjust the imports and namespace to match your specific setup. Additionally, I've kept the original code organization and naming conventions to make it easier to compare with the original JavaScript code.