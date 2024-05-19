package three.js.manual.resources;

import three.js.*;

class ThreeJsTextures {
    static function main() {
        var loader:TextureLoader = new TextureLoader();
        var texturePromise:Promise<Texture> = loadTextureAndPromise('/manual/resources/images/mip-example.png');
        var filterTexture:Texture = texturePromise.texture;
        var filterTexturePromise:Promise<Texture> = texturePromise.promise;

        function filterCube(scale:Float, texture:Texture = filterTexture):Mesh {
            var size:Int = 8;
            var geometry:BoxGeometry = new BoxGeometry(size, size, size);
            var material:MeshBasicMaterial = new MeshBasicMaterial({ map: texture });
            var mesh:Mesh = new Mesh(geometry, material);
            mesh.scale.set(scale, scale, scale);
            return mesh;
        }

        function lowResCube(scale:Float, pixelSize:Int = 16):{
            obj3D:Mesh,
            update:(time:Float, renderInfo:{})->Void,
            render:(renderInfo:{})->Void
        } {
            var mesh:Mesh = filterCube(scale);
            var renderTarget:WebGLRenderTarget = new WebGLRenderTarget(1, 1, { magFilter:NearestFilter, minFilter:NearestFilter });
            var planeScene:Scene = new Scene();
            var plane:PlaneGeometry = new PlaneGeometry(1, 1);
            var planeMaterial:MeshBasicMaterial = new MeshBasicMaterial({ map: renderTarget.texture });
            var planeMesh:Mesh = new Mesh(plane, planeMaterial);
            planeScene.add(planeMesh);

            var planeCamera:OrthographicCamera = new OrthographicCamera(0, 1, 0, 1, -1, 1);
            planeCamera.position.z = 1;

            return {
                obj3D: mesh,
                update: function(time:Float, renderInfo:{}) {
                    var width:Int = renderInfo.width;
                    var height:Int = renderInfo.height;
                    var pixelRatio:Float = renderInfo.pixelRatio;
                    var rtWidth:Int = Math.ceil(width / pixelRatio / pixelSize);
                    var rtHeight:Int = Math.ceil(height / pixelRatio / pixelSize);
                    renderTarget.setSize(rtWidth, rtHeight);

                    planeCamera.aspect = rtWidth / rtHeight;
                    planeCamera.updateProjectionMatrix();

                    renderInfo.renderer.setRenderTarget(renderTarget);
                    renderInfo.renderer.render(planeScene, planeCamera);
                    renderInfo.renderer.setRenderTarget(null);
                },
                render: function(renderInfo:{}) {
                    var width:Int = renderInfo.width;
                    var height:Int = renderInfo.height;
                    var pixelRatio:Float = renderInfo.pixelRatio;
                    var viewWidth:Float = width / pixelRatio / pixelSize;
                    var viewHeight:Float = height / pixelRatio / pixelSize;
                    planeCamera.left = -viewWidth / 2;
                    planeCamera.right = viewWidth / 2;
                    planeCamera.top = viewHeight / 2;
                    planeCamera.bottom = -viewHeight / 2;
                    planeCamera.updateProjectionMatrix();

                    planeMesh.scale.set(renderTarget.width, renderTarget.height, 1);

                    renderInfo.renderer.render(planeScene, planeCamera);
                }
            };
        }

        function createMip(level:Int, numLevels:Int, scale:Float):Canvas {
            var u:Float = level / numLevels;
            var size:Int = Math.pow(2, numLevels - level - 1);
            var halfSize:Int = Math.ceil(size / 2);
            var ctx:CanvasRenderingContext2D = js.Browser.document.createElement('canvas').getContext('2d');
            ctx.canvas.width = size * scale;
            ctx.canvas.height = size * scale;
            ctx.scale(scale, scale);
            ctx.fillStyle = 'hsl(${180 + u * 360 | 0},100%,20%)';
            ctx.fillRect(0, 0, size, size);
            ctx.fillStyle = 'hsl(${u * 360 | 0},100%,50%)';
            ctx.fillRect(0, 0, halfSize, halfSize);
            ctx.fillRect(halfSize, halfSize, halfSize, halfSize);
            return ctx.canvas;
        }

        threejsLessonUtils.init({ threejsOptions: { antialias: false } });
        threejsLessonUtils.addDiagrams({
            filterCube: {
                create: function() {
                    return filterCube(1);
                }
            },
            filterCubeSmall: {
                create: function(info:{}) {
                    return lowResCube(.1, info.renderInfo.pixelRatio);
                }
            },
            filterCubeSmallLowRes: {
                create: function() {
                    return lowResCube(1);
                }
            },
            filterCubeMagNearest: {
                async create():Promise<Mesh> {
                    var texture:Texture = await filterTexturePromise;
                    var newTexture:Texture = texture.clone();
                    newTexture.magFilter = NearestFilter;
                    newTexture.needsUpdate = true;
                    return filterCube(1, newTexture);
                }
            },
            filterCubeMagLinear: {
                async create():Promise<Mesh> {
                    var texture:Texture = await filterTexturePromise;
                    var newTexture:Texture = texture.clone();
                    newTexture.magFilter = LinearFilter;
                    newTexture.needsUpdate = true;
                    return filterCube(1, newTexture);
                }
            },
            filterModes: {
                async create(props:{ scene:Scene, camera:Camera, renderInfo:{} }):{
                    update:(time:Float, renderInfo:{})->Void,
                    trackball:Bool
                } {
                    var scene:Scene = props.scene;
                    var camera:Camera = props.camera;
                    var renderInfo:{} = props.renderInfo;
                    scene.background = new Color('black');
                    camera.far = 150;
                    var texture:Texture = await filterTexturePromise;
                    var root:Object3D = new Object3D();
                    var depth:Int = 50;
                    var plane:PlaneGeometry = new PlaneGeometry(1, depth);
                    var mipmap:Array<Canvas> = [];
                    var numMips:Int = 7;
                    for (i in 0...numMips) {
                        mipmap.push(createMip(i, numMips, 1));
                    }

                    var meshInfos:Array<{
                        x:Float,
                        y:Float,
                        minFilter:Int,
                        magFilter:Int
                    }> = [
                        { x: -1, y: 1, minFilter: NearestFilter, magFilter: NearestFilter },
                        { x: 0, y: 1, minFilter: LinearFilter, magFilter: LinearFilter },
                        { x: 1, y: 1, minFilter: NearestMipmapNearestFilter, magFilter: LinearFilter },
                        { x: -1, y: -1, minFilter: NearestMipmapLinearFilter, magFilter: LinearFilter },
                        { x: 0, y: -1, minFilter: LinearMipmapNearestFilter, magFilter: LinearFilter },
                        { x: 1, y: -1, minFilter: LinearMipmapLinearFilter, magFilter: LinearFilter }
                    ].map(function(info) {
                        var copyTexture:Texture = texture.clone();
                        copyTexture.minFilter = info.minFilter;
                        copyTexture.magFilter = info.magFilter;
                        copyTexture.wrapT = RepeatWrapping;
                        copyTexture.repeat.y = depth;
                        copyTexture.needsUpdate = true;

                        var mipTexture:CanvasTexture = new CanvasTexture(mipmap[0]);
                        mipTexture.mipmaps = mipmap;
                        mipTexture.minFilter = info.minFilter;
                        mipTexture.magFilter = info.magFilter;
                        mipTexture.wrapT = RepeatWrapping;
                        mipTexture.repeat.y = depth;

                        var material:MeshBasicMaterial = new MeshBasicMaterial({ map: copyTexture });
                        var mesh:Mesh = new Mesh(plane, material);
                        mesh.rotation.x = Math.PI * .5 * info.y;
                        mesh.position.x = info.x * 1.5;
                        mesh.position.y = info.y;
                        root.add(mesh);
                        return {
                            material: material,
                            copyTexture: copyTexture,
                            mipTexture: mipTexture
                        };
                    });
                    scene.add(root);

                    renderInfo.elem.addEventListener('click', function() {
                        for (meshInfo in meshInfos) {
                            var material:MeshBasicMaterial = meshInfo.material;
                            material.map = material.map == meshInfo.copyTexture ? meshInfo.mipTexture : meshInfo.copyTexture;
                        }
                    });

                    return {
                        update: function(time:Float, renderInfo:{}):Void {
                            camera.position.y = Math.sin(time * .2) * .5;
                        },
                        trackball: false
                    };
                }
            }
        });

        var textureDiagrams:{} = {
            differentColoredMips: function(parent:HtmlElement) {
                var numMips:Int = 7;
                for (i in 0...numMips) {
                    var elem:HtmlElement = createMip(i, numMips, 4);
                    elem.className = 'border';
                    elem.style.margin = '1px';
                    parent.appendChild(elem);
                }
            }
        };

        function createTextureDiagram(elem:HtmlElement) {
            var name:String = elem.dataset.textureDiagram;
            var info:Void->Void = textureDiagrams[name];
            info(elem);
        }

        js.Browser.document.querySelectorAll('[data-texture-diagram]').forEach(createTextureDiagram);
    }
}