import three.THREE;
import js.libs.potpack.Potpack;

class ProgressiveLightMap {

    var renderer:THREE.WebGLRenderer;
    var res:Int;
    var lightMapContainers:Array<Dynamic>;
    var compiled:Bool;
    var scene:THREE.Scene;
    var tinyTarget:THREE.WebGLRenderTarget;
    var buffer1Active:Bool;
    var firstUpdate:Bool;
    var warned:Bool;
    var progressiveLightMap1:THREE.WebGLRenderTarget;
    var progressiveLightMap2:THREE.WebGLRenderTarget;
    var uvMat:THREE.MeshPhongMaterial;
    var uv_boxes:Array<Dynamic>;
    var blurringPlane:THREE.Mesh;
    var labelMesh:THREE.Mesh;
    var labelMaterial:THREE.MeshBasicMaterial;
    var labelPlane:THREE.PlaneGeometry;

    public function new(renderer:THREE.WebGLRenderer, res:Int = 1024) {
        this.renderer = renderer;
        this.res = res;
        this.lightMapContainers = [];
        this.compiled = false;
        this.scene = new THREE.Scene();
        this.scene.background = null;
        this.tinyTarget = new THREE.WebGLRenderTarget(1, 1);
        this.buffer1Active = false;
        this.firstUpdate = true;
        this.warned = false;

        var format = js.Browser.userAgent.match(new EReg("/(Android|iPad|iPhone|iPod)/", "g")) != null ? THREE.HalfFloatType : THREE.FloatType;
        this.progressiveLightMap1 = new THREE.WebGLRenderTarget(this.res, this.res, { type: format });
        this.progressiveLightMap2 = new THREE.WebGLRenderTarget(this.res, this.res, { type: format });
        this.progressiveLightMap2.texture.channel = 1;

        this.uvMat = new THREE.MeshPhongMaterial();
        this.uvMat.uniforms = {};
        this.uvMat.onBeforeCompile = function(shader) {
            shader.vertexShader = 'attribute vec2 uv1;\n' + '#define USE_LIGHTMAP\n' + '#define LIGHTMAP_UV uv1\n' + shader.vertexShader.substring(0, shader.vertexShader.length - 1) + '	gl_Position = vec4((LIGHTMAP_UV - 0.5) * 2.0, 1.0, 1.0); }';
            var bodyStart = shader.fragmentShader.indexOf('void main() {');
            shader.fragmentShader = '#define USE_LIGHTMAP\n' + shader.fragmentShader.substring(0, bodyStart) + '	uniform sampler2D previousShadowMap;\n	uniform float averagingWindow;\n' + shader.fragmentShader.substring(bodyStart - 1, shader.fragmentShader.length - 1) + `\nvec3 texelOld = texture2D(previousShadowMap, vLightMapUv).rgb;
            gl_FragColor.rgb = mix(texelOld, gl_FragColor.rgb, 1.0/averagingWindow);
            }`;
            shader.uniforms.previousShadowMap = { value: this.progressiveLightMap1.texture };
            shader.uniforms.averagingWindow = { value: 100 };
            this.uvMat.uniforms = shader.uniforms;
            this.uvMat.userData.shader = shader;
            this.compiled = true;
        }
    }

    public function addObjectsToLightMap(objects:Array<THREE.Object3D>) {
        this.uv_boxes = [];
        var padding = 3 / this.res;
        for (object in objects) {
            if (object.isLight) {
                this.scene.attach(object);
                continue;
            }
            if (!object.geometry.hasAttribute('uv')) {
                js.Browser.console.warn('All lightmap objects need UVs!');
                continue;
            }
            if (this.blurringPlane == null) {
                this._initializeBlurPlane(this.res, this.progressiveLightMap1);
            }
            object.material.lightMap = this.progressiveLightMap2.texture;
            object.material.dithering = true;
            object.castShadow = true;
            object.receiveShadow = true;
            object.renderOrder = 1000 + objects.indexOf(object);
            this.uv_boxes.push({ w: 1 + (padding * 2), h: 1 + (padding * 2), index: objects.indexOf(object) });
            this.lightMapContainers.push({ basicMat: object.material, object: object });
            this.compiled = false;
        }
        var dimensions = Potpack.pack(this.uv_boxes);
        for (box in this.uv_boxes) {
            var uv1 = objects[box.index].geometry.getAttribute('uv').clone();
            for (i in 0...uv1.array.length) if (i % uv1.itemSize == 0) {
                uv1.array[i] = (uv1.array[i] + box.x + padding) / dimensions.w;
                uv1.array[i + 1] = (uv1.array[i + 1] + box.y + padding) / dimensions.h;
            }
            objects[box.index].geometry.setAttribute('uv1', uv1);
            objects[box.index].geometry.getAttribute('uv1').needsUpdate = true;
        }
    }

    public function update(camera:THREE.Camera, blendWindow:Int = 100, blurEdges:Bool = true) {
        if (this.blurringPlane == null) {
            return;
        }
        var oldTarget = this.renderer.getRenderTarget();
        this.blurringPlane.visible = blurEdges;
        for (l in 0...this.lightMapContainers.length) {
            this.lightMapContainers[l].object.oldScene = this.lightMapContainers[l].object.parent;
            this.scene.attach(this.lightMapContainers[l].object);
        }
        if (this.firstUpdate) {
            this.renderer.setRenderTarget(this.tinyTarget);
            this.renderer.render(this.scene, camera);
            this.firstUpdate = false;
        }
        for (l in 0...this.lightMapContainers.length) {
            this.uvMat.uniforms.averagingWindow = { value: blendWindow };
            this.lightMapContainers[l].object.material = this.uvMat;
            this.lightMapContainers[l].object.oldFrustumCulled = this.lightMapContainers[l].object.frustumCulled;
            this.lightMapContainers[l].object.frustumCulled = false;
        }
        var activeMap = this.buffer1Active ? this.progressiveLightMap1 : this.progressiveLightMap2;
        var inactiveMap = this.buffer1Active ? this.progressiveLightMap2 : this.progressiveLightMap1;
        this.renderer.setRenderTarget(activeMap);
        this.uvMat.uniforms.previousShadowMap = { value: inactiveMap.texture };
        this.blurringPlane.material.uniforms.previousShadowMap = { value: inactiveMap.texture };
        this.buffer1Active = !this.buffer1Active;
        this.renderer.render(this.scene, camera);
        for (l in 0...this.lightMapContainers.length) {
            this.lightMapContainers[l].object.frustumCulled = this.lightMapContainers[l].object.oldFrustumCulled;
            this.lightMapContainers[l].object.material = this.lightMapContainers[l].basicMat;
            this.lightMapContainers[l].object.oldScene.attach(this.lightMapContainers[l].object);
        }
        this.renderer.setRenderTarget(oldTarget);
    }

    public function showDebugLightmap(visible:Bool, position:THREE.Vector3 = null) {
        if (this.lightMapContainers.length == 0) {
            if (!this.warned) {
                js.Browser.console.warn('Call this after adding the objects!');
                this.warned = true;
            }
            return;
        }
        if (this.labelMesh == null) {
            this.labelMaterial = new THREE.MeshBasicMaterial({ map: this.progressiveLightMap1.texture, side: THREE.DoubleSide });
            this.labelPlane = new THREE.PlaneGeometry(100, 100);
            this.labelMesh = new THREE.Mesh(this.labelPlane, this.labelMaterial);
            this.labelMesh.position.y = 250;
            this.lightMapContainers[0].object.parent.add(this.labelMesh);
        }
        if (position != null) {
            this.labelMesh.position.copy(position);
        }
        this.labelMesh.visible = visible;
    }

    private function _initializeBlurPlane(res:Int, lightMap:THREE.WebGLRenderTarget = null) {
        var blurMaterial = new THREE.MeshBasicMaterial();
        blurMaterial.uniforms = { previousShadowMap: { value: null }, pixelOffset: { value: 1.0 / res }, polygonOffset: true, polygonOffsetFactor: -1, polygonOffsetUnits: 3.0 };
        blurMaterial.onBeforeCompile = function(shader) {
            shader.vertexShader = '#define USE_UV\n' + shader.vertexShader.substring(0, shader.vertexShader.length - 1) + '	gl_Position = vec4((uv - 0.5) * 2.0, 1.0, 1.0); }';
            var bodyStart = shader.fragmentShader.indexOf('void main() {');
            shader.fragmentShader = '#define USE_UV\n' + shader.fragmentShader.substring(0, bodyStart) + '	uniform sampler2D previousShadowMap;\n	uniform float pixelOffset;\n' + shader.fragmentShader.substring(bodyStart - 1, shader.fragmentShader.length - 1) + `	gl_FragColor.rgb = (
                                    texture2D(previousShadowMap, vUv + vec2( pixelOffset,  0.0        )).rgb +
                                    texture2D(previousShadowMap, vUv + vec2( 0.0        ,  pixelOffset)).rgb +
                                    texture2D(previousShadowMap, vUv + vec2( 0.0        , -pixelOffset)).rgb +
                                    texture2D(previousShadowMap, vUv + vec2(-pixelOffset,  0.0        )).rgb +
                                    texture2D(previousShadowMap, vUv + vec2( pixelOffset,  pixelOffset)).rgb +
                                    texture2D(previousShadowMap, vUv + vec2(-pixelOffset,  pixelOffset)).rgb +
                                    texture2D(previousShadowMap, vUv + vec2( pixelOffset, -pixelOffset)).rgb +
                                    texture2D(previousShadowMap, vUv + vec2(-pixelOffset, -pixelOffset)).rgb)/8.0;
            }`;
            shader.uniforms.previousShadowMap = { value: lightMap.texture };
            shader.uniforms.pixelOffset = { value: 0.5 / res };
            blurMaterial.uniforms = shader.uniforms;
            blurMaterial.userData.shader = shader;
            this.compiled = true;
        }
        this.blurringPlane = new THREE.Mesh(new THREE.PlaneGeometry(1, 1), blurMaterial);
        this.blurringPlane.name = 'Blurring Plane';
        this.blurringPlane.frustumCulled = false;
        this.blurringPlane.renderOrder = 0;
        this.blurringPlane.material.depthWrite = false;
        this.scene.add(this.blurringPlane);
    }
}