package three.js.manual.resources;

import three.js.Three;

class ThreejsTextures {
    static function main() {
        var loader = new Three.TextureLoader();

        function loadTextureAndPromise(url:String):{ texture:Three.Texture, promise:Promise<Three.Texture> } {
            var textureResolve:Three.Texture->Void;
            var promise = new Promise((resolve) -> {
                textureResolve = resolve;
            });
            var texture = loader.load(url, (texture) -> {
                textureResolve(texture);
            });
            return { texture: texture, promise: promise };
        }

        var filterTextureInfo = loadTextureAndPromise('/manual/resources/images/mip-example.png');
        var filterTexture = filterTextureInfo.texture;
        var filterTexturePromise = filterTextureInfo.promise;

        function filterCube(scale:Float, texture:Three.Texture = null):Three.Mesh {
            var size = 8;
            var geometry = new Three.BoxGeometry(size, size, size);
            var material = new Three.MeshBasicMaterial({
                map: texture != null ? texture : filterTexture,
            });
            var mesh = new Three.Mesh(geometry, material);
            mesh.scale.set(scale, scale, scale);
            return mesh;
        }

        function lowResCube(scale:Float, pixelSize:Int = 16):{ obj3D:Three.Object3D, update:(time:Float, renderInfo:{ width:Int, height:Int, scene:Three.Scene, camera:Three.Camera, renderer:Three.WebGLRenderer, pixelRatio:Float })->Void, render:(renderInfo:{ width:Int, height:Int, renderer:Three.WebGLRenderer, pixelRatio:Float })->Void } {
            var mesh = filterCube(scale);
            var renderTarget = new Three.WebGLRenderTarget(1, 1, {
                magFilter: Three.NearestFilter,
                minFilter: Three.NearestFilter,
            });

            var planeScene = new Three.Scene();
            var plane = new Three.PlaneGeometry(1, 1);
            var planeMaterial = new Three.MeshBasicMaterial({
                map: renderTarget.texture,
            });
            var planeMesh = new Three.Mesh(plane, planeMaterial);
            planeScene.add(planeMesh);

            var planeCamera = new Three.OrthographicCamera(0, 1, 0, 1, -1, 1);
            planeCamera.position.z = 1;

            return {
                obj3D: mesh,
                update: function(time:Float, renderInfo:{ width:Int, height:Int, scene:Three.Scene, camera:Three.Camera, renderer:Three.WebGLRenderer, pixelRatio:Float }) {
                    var width = renderInfo.width;
                    var height = renderInfo.height;
                    renderTarget.setSize(Math.ceil(width / renderInfo.pixelRatio / pixelSize), Math.ceil(height / renderInfo.pixelRatio / pixelSize));
                    planeCamera.aspect = renderTarget.width / renderTarget.height;
                    planeCamera.updateProjectionMatrix();
                    renderInfo.renderer.setRenderTarget(renderTarget);
                    renderInfo.renderer.render(renderInfo.scene, planeCamera);
                    renderInfo.renderer.setRenderTarget(null);
                },
                render: function(renderInfo:{ width:Int, height:Int, renderer:Three.WebGLRenderer, pixelRatio:Float }) {
                    var width = renderInfo.width;
                    var height = renderInfo.height;
                    var viewWidth = width / renderInfo.pixelRatio / pixelSize;
                    var viewHeight = height / renderInfo.pixelRatio / pixelSize;
                    planeCamera.left = -viewWidth / 2;
                    planeCamera.right = viewWidth / 2;
                    planeCamera.top = viewHeight / 2;
                    planeCamera.bottom = -viewHeight / 2;
                    planeCamera.updateProjectionMatrix();
                    planeMesh.scale.set(renderTarget.width, renderTarget.height, 1);
                    renderInfo.renderer.render(planeScene, planeCamera);
                },
            };
        }

        function createMip(level:Int, numLevels:Int, scale:Float):js.html.CanvasElement {
            var u = level / numLevels;
            var size = Math.pow(2, numLevels - level - 1);
            var halfSize = Math.ceil(size / 2);
            var ctx:js.html.CanvasRenderingContext2D = js.Browser.createCanvasElement().getContext('2d');
            ctx.canvas.width = size * scale;
            ctx.canvas.height = size * scale;
            ctx.scale(scale, scale);
            ctx.fillStyle = 'hsl(' + (180 + u * 360) + ',100%,20%)';
            ctx.fillRect(0, 0, size, size);
            ctx.fillStyle = 'hsl(' + (u * 360) + ',100%,50%)';
            ctx.fillRect(0, 0, halfSize, halfSize);
            ctx.fillRect(halfSize, halfSize, halfSize, halfSize);
            return ctx.canvas;
        }

        threejsLessonUtils.init({
            threejsOptions: {
                antialias: false,
            },
        });

        threejsLessonUtils.addDiagrams({
            filterCube: {
                create: function() {
                    return filterCube(1);
                },
            },
            filterCubeSmall: {
                create: function(info:{ renderInfo:{ width:Int, height:Int, pixelRatio:Float } }) {
                    return lowResCube(.1, info.renderInfo.pixelRatio);
                },
            },
            filterCubeSmallLowRes: {
                create: function() {
                    return lowResCube(1);
                },
            },
            filterCubeMagNearest: {
                asyncCreate: function() {
                    var texture = await filterTexturePromise;
                    var newTexture = texture.clone();
                    newTexture.magFilter = Three.NearestFilter;
                    newTexture.needsUpdate = true;
                    return filterCube(1, newTexture);
                },
            },
            filterCubeMagLinear: {
                asyncCreate: function() {
                    var texture = await filterTexturePromise;
                    var newTexture = texture.clone();
                    newTexture.magFilter = Three.LinearFilter;
                    newTexture.needsUpdate = true;
                    return filterCube(1, newTexture);
                },
            },
            filterModes: {
                asyncCreate: function(props:{ scene:Three.Scene, camera:Three.Camera, renderInfo:{ width:Int, height:Int, pixelRatio:Float } }) {
                    props.scene.background = new Three.Color('black');
                    props.camera.far = 150;
                    var texture = await filterTexturePromise;
                    var root = new Three.Object3D();
                    var depth = 50;
                    var plane = new Three.PlaneGeometry(1, depth);
                    var mipmap = [];
                    var numMips = 7;
                    for (i in 0...numMips) {
                        mipmap.push(createMip(i, numMips, 1));
                    }

                    var meshInfos = [
                        { x: -1, y: 1, minFilter: Three.NearestFilter, magFilter: Three.NearestFilter },
                        { x: 0, y: 1, minFilter: Three.LinearFilter, magFilter: Three.LinearFilter },
                        { x: 1, y: 1, minFilter: Three.NearestMipmapNearestFilter, magFilter: Three.LinearFilter },
                        { x: -1, y: -1, minFilter: Three.NearestMipmapLinearFilter, magFilter: Three.LinearFilter },
                        { x: 0, y: -1, minFilter: Three.LinearMipmapNearestFilter, magFilter: Three.LinearFilter },
                        { x: 1, y: -1, minFilter: Three.LinearMipmapLinearFilter, magFilter: Three.LinearFilter },
                    ].map((info) -> {
                        var copyTexture = texture.clone();
                        copyTexture.minFilter = info.minFilter;
                        copyTexture.magFilter = info.magFilter;
                        copyTexture.wrapT = Three.RepeatWrapping;
                        copyTexture.repeat.y = depth;
                        copyTexture.needsUpdate = true;

                        var mipTexture = new Three.CanvasTexture(mipmap[0]);
                        mipTexture.mipmaps = mipmap;
                        mipTexture.minFilter = info.minFilter;
                        mipTexture.magFilter = info.magFilter;
                        mipTexture.wrapT = Three.RepeatWrapping;
                        mipTexture.repeat.y = depth;

                        var material = new Three.MeshBasicMaterial({
                            map: copyTexture,
                        });

                        var mesh = new Three.Mesh(plane, material);
                        mesh.rotation.x = Math.PI * .5 * info.y;
                        mesh.position.x = info.x * 1.5;
                        mesh.position.y = info.y;
                        root.add(mesh);
                        return {
                            material: material,
                            copyTexture: copyTexture,
                            mipTexture: mipTexture,
                        };
                    });
                    props.scene.add(root);

                    props.renderInfo.elem.addEventListener('click', () -> {
                        for (meshInfo in meshInfos) {
                            var { material, copyTexture, mipTexture } = meshInfo;
                            material.map = material.map == copyTexture ? mipTexture : copyTexture;
                        }
                    });

                    return {
                        update: function(time:Float, renderInfo:{ width:Int, height:Int, scene:Three.Scene, camera:Three.Camera, renderer:Three.WebGLRenderer, pixelRatio:Float }) {
                            props.camera.position.y = Math.sin(time * .2) * .5;
                        },
                        trackball: false,
                    };
                },
            },
        });

        var textureDiagrams = {
            differentColoredMips: function(parent:js.html.Element) {
                var numMips = 7;
                for (i in 0...numMips) {
                    var elem = createMip(i, numMips, 4);
                    elem.className = 'border';
                    elem.style.margin = '1px';
                    parent.appendChild(elem);
                }
            },
        };

        function createTextureDiagram(elem:js.html.Element) {
            var name = elem.dataset.textureDiagram;
            var info = textureDiagrams[name];
            info(elem);
        }

        for (elem in js.Browser.document.querySelectorAll('[data-texture-diagram]')) {
            createTextureDiagram(elem);
        }
    }
}