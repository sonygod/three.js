import three.js.Lib;
import three.addons.loaders.KTX2Loader;
import three.addons.loaders.RGBELoader;
import three.addons.loaders.TGALoader;
import three.addons.postprocessing.FullScreenQuad;

class UITexture extends UISpan {
    private var cache:Map<String, THREE.Texture>;
    private var texture:THREE.Texture;
    private var onChangeCallback:Void->Void;

    public function new(editor:Dynamic) {
        super();
        cache = new Map();
        var form:HtmlFormElement = Lib.createElement("form");
        var input:HtmlInputElement = Lib.createElement("input");
        input.type = "file";
        input.addEventListener("change", function(event) {
            loadFile(event.target.files[0]);
        });
        form.appendChild(input);

        var canvas:HtmlCanvasElement = Lib.createElement("canvas");
        canvas.width = 32;
        canvas.height = 16;
        canvas.style.cursor = "pointer";
        canvas.style.marginRight = "5px";
        canvas.style.border = "1px solid #888";
        canvas.addEventListener("click", function() {
            input.click();
        });
        canvas.addEventListener("drop", function(event) {
            event.preventDefault();
            event.stopPropagation();
            loadFile(event.dataTransfer.files[0]);
        });
        this.dom.appendChild(canvas);

        function loadFile(file:File) {
            var extension:String = file.name.split(".").pop().toLowerCase();
            var reader:FileReader = new FileReader();
            var hash:String = "${file.lastModified}_${file.size}_${file.name}";

            if (cache.exists(hash)) {
                var texture:THREE.Texture = cache.get(hash);
                setValue(texture);
                if (onChangeCallback != null) onChangeCallback();
            } else if (extension == "hdr" || extension == "pic") {
                reader.addEventListener("load", function(event) {
                    var loader:RGBELoader = new RGBELoader();
                    loader.load(event.target.result, function(hdrTexture:THREE.Texture) {
                        hdrTexture.sourceFile = file.name;
                        cache.set(hash, hdrTexture);
                        setValue(hdrTexture);
                        if (onChangeCallback != null) onChangeCallback();
                    });
                });
                reader.readAsDataURL(file);
            } else if (extension == "tga") {
                reader.addEventListener("load", function(event) {
                    var loader:TGALoader = new TGALoader();
                    loader.load(event.target.result, function(texture:THREE.Texture) {
                        texture.colorSpace = THREE.SRGBColorSpace;
                        texture.sourceFile = file.name;
                        cache.set(hash, texture);
                        setValue(texture);
                        if (onChangeCallback != null) onChangeCallback();
                    });
                });
                reader.readAsDataURL(file);
            } else if (extension == "ktx2") {
                reader.addEventListener("load", function(event) {
                    var arrayBuffer:ArrayBuffer = event.target.result;
                    var blobURL:String = URL.createObjectURL(new Blob([arrayBuffer]));
                    var ktx2Loader:KTX2Loader = new KTX2Loader();
                    ktx2Loader.setTranscoderPath("../../examples/jsm/libs/basis/");
                    editor.signals.rendererDetectKTX2Support.dispatch(ktx2Loader);
                    ktx2Loader.load(blobURL, function(texture:THREE.Texture) {
                        texture.colorSpace = THREE.SRGBColorSpace;
                        texture.sourceFile = file.name;
                        texture.needsUpdate = true;
                        cache.set(hash, texture);
                        setValue(texture);
                        if (onChangeCallback != null) onChangeCallback();
                        ktx2Loader.dispose();
                    });
                });
                reader.readAsArrayBuffer(file);
            } else if (file.type.match(/^image\/.*/)) {
                reader.addEventListener("load", function(event) {
                    var image:HtmlImageElement = Lib.createElement("img");
                    image.addEventListener("load", function() {
                        var texture:THREE.Texture = new THREE.Texture(image);
                        texture.sourceFile = file.name;
                        texture.needsUpdate = true;
                        cache.set(hash, texture);
                        setValue(texture);
                        if (onChangeCallback != null) onChangeCallback();
                    });
                    image.src = event.target.result;
                });
                reader.readAsDataURL(file);
            }

            form.reset();
        }

        texture = null;
        onChangeCallback = null;
    }

    public function getValue():THREE.Texture {
        return texture;
    }

    public function setValue(texture:THREE.Texture) {
        var canvas:HtmlCanvasElement = cast this.dom.children[0];
        var context:CanvasRenderingContext2D = canvas.getContext("2d");
        if (context != null) {
            context.clearRect(0, 0, canvas.width, canvas.height);
        }
        if (texture != null) {
            var image:HtmlImageElement = texture.image;
            if (image != null && image.width > 0) {
                canvas.title = texture.sourceFile;
                var scale:Float = canvas.width / image.width;
                if (texture.isDataTexture || texture.isCompressedTexture) {
                    var canvas2:HtmlCanvasElement = renderToCanvas(texture);
                    context.drawImage(canvas2, 0, 0, image.width * scale, image.height * scale);
                } else {
                    context.drawImage(image, 0, 0, image.width * scale, image.height * scale);
                }
            } else {
                canvas.title = texture.sourceFile + " (error)";
            }
        } else {
            canvas.title = "empty";
        }
        texture = texture;
    }

    public function setColorSpace(colorSpace:THREE.ColorSpace):UITexture {
        var texture:THREE.Texture = getValue();
        if (texture != null) {
            texture.colorSpace = colorSpace;
        }
        return this;
    }

    public function onChange(callback:Void->Void):UITexture {
        onChangeCallback = callback;
        return this;
    }
}

class UIOutliner extends UIDiv {
    private var scene:THREE.Scene;
    private var selectedIndex:Int;
    private var selectedValue:Dynamic;

    public function new(editor:Dynamic) {
        super();
        dom.className = "Outliner";
        dom.tabIndex = 0; // hack
        scene = editor.scene;

        dom.addEventListener("keydown", function(event) {
            switch (event.code) {
                case "ArrowUp":
                case "ArrowDown":
                    event.preventDefault();
                    event.stopPropagation();
            }
        });

        dom.addEventListener("keyup", function(event) {
            switch (event.code) {
                case "ArrowUp":
                    selectIndex(selectedIndex - 1);
                case "ArrowDown":
                    selectIndex(selectedIndex + 1);
            }
        });

        options = [];
        selectedIndex = -1;
        selectedValue = null;
    }

    public function selectIndex(index:Int) {
        if (index >= 0 && index < options.length) {
            setValue(options[index].value);
            var changeEvent:Event = new Event("change", true, true);
            dom.dispatchEvent(changeEvent);
        }
    }

    public function setOptions(options:Array<Dynamic>) {
        while (dom.children.length > 0) {
            dom.removeChild(dom.firstChild);
        }

        function onClick() {
            setValue(this.value);
            var changeEvent:Event = new Event("change", true, true);
            dom.dispatchEvent(changeEvent);
        }

        function onDrag() {
            currentDrag = this;
        }

        function onDragStart(event) {
            event.dataTransfer.setData("text", "foo");
        }

        function onDragOver(event) {
            if (this == currentDrag) return;
            var area:Float = event.offsetY / this.clientHeight;
            if (area < 0.25) {
                this.className = "option dragTop";
            } else if (area > 0.75) {
                this.className = "option dragBottom";
            } else {
                this.className = "option drag";
            }
        }

        function onDragLeave() {
            if (this == currentDrag) return;
            this.className = "option";
        }

        function onDrop(event) {
            if (this == currentDrag || currentDrag == null) return;
            this.className = "option";

            var scene:THREE.Scene = scene;
            var object:THREE.Object3D = scene.getObjectById(currentDrag.value);

            var area:Float = event.offsetY / this.clientHeight;

            if (area < 0.25) {
                var nextObject:THREE.Object3D = scene.getObjectById(this.value);
                moveObject(object, nextObject.parent, nextObject);
            } else if (area > 0.75) {
                var nextObject:THREE.Object3D;
                var parent:THREE.Object3D;
                if (this.nextSibling != null) {
                    nextObject = scene.getObjectById(this.nextSibling.value);
                    parent = nextObject.parent;
                } else {
                    nextObject = null;
                    parent = scene.getObjectById(this.value).parent;
                }

                moveObject(object, parent, nextObject);
            } else {
                var parentObject:THREE.Object3D = scene.getObjectById(this.value);
                moveObject(object, parentObject);
            }
        }

        function moveObject(object:THREE.Object3D, newParent:THREE.Object3D, nextObject:THREE.Object3D) {
            if (nextObject == null) nextObject = undefined;

            var newParentIsChild:Bool = false;

            object.traverse(function(child:THREE.Object3D) {
                if (child == newParent) newParentIsChild = true;
            });

            if (newParentIsChild) return;

            var editor:Dynamic = editor;
            editor.execute(new MoveObjectCommand(editor, object, newParent, nextObject));

            var changeEvent:Event = new Event("change", true, true);
            dom.dispatchEvent(changeEvent);
        }

        for (option in options) {
            var div:HtmlDivElement = Lib.createElement("div");
            div.className = "option";
            dom.appendChild(div);

            option.addEventListener("click", onClick);

            if (option.draggable) {
                option.addEventListener("drag", onDrag);
                option.addEventListener("dragstart", onDragStart); // Firefox needs this

                option.addEventListener("dragover", onDragOver);
                option.addEventListener("dragleave", onDragLeave);
                option.addEventListener("drop", onDrop);
            }

            options.push(div);
        }

        return this;
    }

    public function getValue():Dynamic {
        return selectedValue;
    }

    public function setValue(value:Dynamic) {
        for (i in 0...options.length) {
            var element:HtmlDivElement = options[i];
            if (element.value == value) {
                element.classList.add("active");
                selectedIndex = i;
                selectedValue = value;

                var y:Int = element.offsetTop - dom.offsetTop;
                var bottomY:Int = y + element.offsetHeight;
                var minScroll:Int = bottomY - dom.offsetHeight;

                if (dom.scrollTop > y) {
                    dom.scrollTop = y;
                } else if (dom.scrollTop < minScroll) {
                    dom.scrollTop = minScroll;
                }
            } else {
                element.classList.remove("active");
            }
        }
    }
}

class UIPoints extends UISpan {
    private var pointsUI:Array<Dynamic>;
    private var lastPointIdx:Int;
    private var onChangeCallback:Void->Void;

    public function new() {
        super();
        dom.style.display = "inline-block";

        pointsList = new UIDiv();
        add(pointsList);

        pointsUI = [];
        lastPointIdx = 0;
        onChangeCallback = null;

        update = function() {
            if (onChangeCallback != null) onChangeCallback();
        };
    }

    public function onChange(callback:Void->Void):UIPoints {
        onChangeCallback = callback;
        return this;
    }

    public function clear() {
        for (i in 0...pointsUI.length) {
            if (pointsUI[i] != null) {
                deletePointRow(i, true);
            }
        }

        lastPointIdx = 0;
    }

    public function deletePointRow(idx:Int, dontUpdate:Bool) {
        if (pointsUI[idx] == null) return;

        pointsList.remove(pointsUI[idx].row);

        pointsUI.splice(idx, 1);

        if (!dontUpdate) update();
        lastPointIdx--;
    }
}

class UIPoints2 extends UIPoints {
    public function new() {
        super();

        var row:UIRow = new UIRow();
        add(row);

        var addPointButton:UIButton = new UIButton("+");
        addPointButton.onClick(function() {
            if (pointsUI.length == 0) {
                pointsList.add(createPointRow(0, 0));
            } else {
                var point:UIPointsUI = pointsUI[pointsUI.length - 1];
                pointsList.add(createPointRow(point.x.getValue(), point.y.getValue()));
            }
            update();
        });
        row.add(addPointButton);
    }

    public function getValue():Array<THREE.Vector2> {
        var points:Array<THREE.Vector2> = [];
        var count:Int = 0;

        for (i in 0...pointsUI.length) {
            var pointUI:UIPointsUI = pointsUI[i];
            if (pointUI == null) continue;
            points.push(new THREE.Vector2(pointUI.x.getValue(), pointUI.y.getValue()));
            count++;
            pointUI.lbl.setValue(count);
        }

        return points;
    }

    public function setValue(points:Array<THREE.Vector2>):UIPoints2 {
        clear();

        for (i in 0...points.length) {
            var point:THREE.Vector2 = points[i];
            pointsList.add(createPointRow(point.x, point.y));
        }

        update();
        return this;
    }

    private function createPointRow(x:Float, y:Float):UIDiv {
        var pointRow:UIDiv = new UIDiv();
        var lbl:UIText = new UIText(lastPointIdx + 1).setWidth("20px");
        var txtX:UINumber = new UINumber(x).setWidth("30px").onChange(update);
        var txtY:UINumber = new UINumber(y).setWidth("30px").onChange(update);

        var scope:UIPoints2 = this;
        var btn:UIButton = new UIButton("-").onClick(function() {
            if (scope.isEditing) return;
            var idx:Int = pointsList.getIndexOfChild(pointRow);
            deletePointRow(idx);
        });

        pointsUI.push({ row: pointRow, lbl: lbl, x: txtX, y: txtY });
        lastPointIdx++;
        pointRow.add(lbl, txtX, txtY, btn);

        return pointRow;
    }
}

class UIPoints3 extends UIPoints {
    public function new() {
        super();

        var row:UIRow = new UIRow();
        add(row);

        var addPointButton:UIButton = new UIButton("+");
        addPointButton.onClick(function() {
            if (pointsUI.length == 0) {
                pointsList.add(createPointRow(0, 0, 0));
            } else {
                var point:UIPointsUI = pointsUI[pointsUI.length - 1];
                pointsList.add(createPointRow(point.x.getValue(), point.y.getValue(), point.z.getValue()));
            }
            update();
        });
        row.add(addPointButton);
    }

    public function getValue():Array<THREE.Vector3> {
        var points:Array<THREE.Vector3> = [];
        var count:Int = 0;

        for (i in 0...pointsUI.length) {
            var pointUI:UIPointsUI = pointsUI[i];
            if (pointUI == null) continue;
            points.push(new THREE.Vector3(pointUI.x.getValue(), pointUI.y.getValue(), pointUI.z.getValue()));
            count++;
            pointUI.lbl.setValue(count);
        }

        return points;
    }

    public function setValue(points:Array<THREE.Vector3>):UIPoints3 {
        clear();

        for (i in 0...points.length) {
            var point:THREE.Vector3 = points[i];
            pointsList.add(createPointRow(point.x, point.y, point.z));
        }

        update();
        return this;
    }

    private function createPointRow(x:Float, y:Float, z:Float):UIDiv {
        var pointRow:UIDiv = new UIDiv();
        var lbl:UIText = new UIText(lastPointIdx + 1).setWidth("20px");
        var txtX:UINumber = new UINumber(x).setWidth("30px").onChange(update);
        var txtY:UINumber = new UINumber(y).setWidth("30px").onChange(update);
        var txtZ:UINumber = new UINumber(z).setWidth("30px").onChange(update);

        var scope:UIPoints3 = this;
        var btn:UIButton = new UIButton("-").onClick(function() {
            if (scope.isEditing) return;
            var idx:Int = pointsList.getIndexOfChild(pointRow);
            deletePointRow(idx);
        });

        pointsUI.push({ row: pointRow, lbl: lbl, x: txtX, y: txtY, z: txtZ });
        lastPointIdx++;
        pointRow.add(lbl, txtX, txtY, txtZ, btn);

        return pointRow;
    }
}

class UIBoolean extends UISpan {
    public function new(boolean:Bool, text:String) {
        super();

        setMarginRight("4px");

        checkbox:UICheckbox = new UICheckbox(boolean);
        text:UIText = new UIText(text).setMarginLeft("3px");

        add(checkbox);
        add(text);
    }

    public function getValue():Bool {
        return checkbox.getValue();
    }

    public function setValue(value:Bool):UIBoolean {
        return checkbox.setValue(value);
    }
}

var renderer:THREE.WebGLRenderer;
var fsQuad:FullScreenQuad;

function renderToCanvas(texture:THREE.Texture):HtmlCanvasElement {
    if (renderer == null) renderer = new THREE.WebGLRenderer();

    if (fsQuad == null) fsQuad = new FullScreenQuad(new THREE.MeshBasicMaterial());

    var image:HtmlImageElement = texture.image;

    renderer.setSize(image.width, image.height, false);

    fsQuad.material.map = texture;
    fsQuad.render(renderer);

    return renderer.domElement;
}