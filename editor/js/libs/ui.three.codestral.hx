import js.html.File;
import js.html.FileReader;
import js.html.Image;
import js.html.InputElement;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.Event;
import js.html.HTMLDocument;
import js.html.HTMLFormElement;
import js.html.CanvasRenderingContext2D;
import js.html.HTMLImageElement;
import js.html.Blob;
import js.html.BlobPropertyBag;
import js.html.URL;
import js.html.FileList;
import js.html.DataTransfer;
import js.html.HTMLCanvasElement;
import js.html.DragEvent;
import js.html.MouseEvent;
import js.html.Element;
import js.html.HTMLDivElement;
import js.html.HTMLInputElement;
import js.html.HTMLSpanElement;
import js.html.HTMLButtonElement;
import js.html.HTMLLabelElement;
import js.html.HTMLTextAreaElement;
import js.html.HTMLInputElement;
import js.html.HTMLUListElement;
import js.html.HTMLLIElement;
import js.Browser;
import js.Boot;
import js.ArrayIterator;
import haxe.ds.StringMap;
import haxe.IMap;

import three.THREE;
import three.addons.loaders.KTX2Loader;
import three.addons.loaders.RGBELoader;
import three.addons.loaders.TGALoader;
import three.addons.postprocessing.Pass;

import ui.three.UISpan;
import ui.three.UIDiv;
import ui.three.UIRow;
import ui.three.UIButton;
import ui.three.UICheckbox;
import ui.three.UIText;
import ui.three.UINumber;
import commands.MoveObjectCommand;

class UITexture extends UISpan {
    public var texture: THREE.Texture;
    public var onChangeCallback: Null<() -> Void>;

    public function new(editor: Editor) {
        super();

        var form: HTMLFormElement = js.html.Document.createElement("form").cast();
        var input: HTMLInputElement = js.html.Document.createElement("input").cast();
        input.type = "file";
        input.addEventListener("change", (event: Event) -> {
            var files: FileList = event.target.cast<InputElement>().files;
            if (files.length > 0) {
                loadFile(files[0]);
            }
        });
        form.appendChild(input);

        var canvas: HTMLCanvasElement = js.html.Document.createElement("canvas").cast();
        canvas.width = 32;
        canvas.height = 16;
        canvas.style.cursor = "pointer";
        canvas.style.marginRight = "5px";
        canvas.style.border = "1px solid #888";
        canvas.addEventListener("click", (event: Event) -> {
            input.click();
        });
        canvas.addEventListener("drop", (event: DragEvent) -> {
            event.preventDefault();
            event.stopPropagation();
            var files: FileList = event.dataTransfer.files;
            if (files.length > 0) {
                loadFile(files[0]);
            }
        });
        this.dom.appendChild(canvas);

        this.texture = null;
        this.onChangeCallback = null;

        var cache: IMap<String, THREE.Texture> = new StringMap<THREE.Texture>();

        function loadFile(file: File) {
            var extension: String = file.name.split('.').pop().toLowerCase();
            var reader: FileReader = new FileReader();

            var hash: String = file.lastModified + "_" + file.size + "_" + file.name;

            if (cache.exists(hash)) {
                var texture: THREE.Texture = cache.get(hash);
                setValue(texture);
                if (onChangeCallback != null) onChangeCallback();
            } else if (extension == "hdr" || extension == "pic") {
                reader.addEventListener("load", (event: Event) -> {
                    var loader: RGBELoader = new RGBELoader();
                    loader.load(event.target.cast<FileReader>().result.cast<String>(), (hdrTexture: THREE.Texture) -> {
                        hdrTexture.sourceFile = file.name;
                        cache.set(hash, hdrTexture);
                        setValue(hdrTexture);
                        if (onChangeCallback != null) onChangeCallback();
                    });
                });
                reader.readAsDataURL(file);
            } else if (extension == "tga") {
                reader.addEventListener("load", (event: Event) -> {
                    var loader: TGALoader = new TGALoader();
                    loader.load(event.target.cast<FileReader>().result.cast<String>(), (texture: THREE.Texture) -> {
                        texture.colorSpace = THREE.SRGBColorSpace;
                        texture.sourceFile = file.name;
                        cache.set(hash, texture);
                        setValue(texture);
                        if (onChangeCallback != null) onChangeCallback();
                    });
                });
                reader.readAsDataURL(file);
            } else if (extension == "ktx2") {
                reader.addEventListener("load", (event: Event) -> {
                    var arrayBuffer: ArrayBuffer = event.target.cast<FileReader>().result.cast<ArrayBuffer>();
                    var blob: Blob = new Blob([arrayBuffer], new BlobPropertyBag(mimeType = "application/octet-stream"));
                    var blobURL: String = URL.createObjectURL(blob);
                    var ktx2Loader: KTX2Loader = new KTX2Loader();
                    ktx2Loader.setTranscoderPath("../../examples/jsm/libs/basis/");
                    editor.signals.rendererDetectKTX2Support.dispatch(ktx2Loader);

                    ktx2Loader.load(blobURL, (texture: THREE.Texture) -> {
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
            } else if (file.type.match("image.*") != null) {
                reader.addEventListener("load", (event: Event) -> {
                    var image: HTMLImageElement = js.html.Document.createElement("img").cast();
                    image.addEventListener("load", (event: Event) -> {
                        var texture: THREE.Texture = new THREE.Texture(image);
                        texture.sourceFile = file.name;
                        texture.needsUpdate = true;
                        cache.set(hash, texture);
                        setValue(texture);
                        if (onChangeCallback != null) onChangeCallback();
                    });
                    image.src = event.target.cast<FileReader>().result.cast<String>();
                });
                reader.readAsDataURL(file);
            }
            form.reset();
        }
    }

    public function getValue(): THREE.Texture {
        return texture;
    }

    public function setValue(texture: THREE.Texture): UITexture {
        var canvas: HTMLCanvasElement = this.dom.children[0].cast();
        var context: CanvasRenderingContext2D = canvas.getContext("2d").cast();

        if (context != null) {
            context.clearRect(0, 0, canvas.width, canvas.height);
        }

        if (texture != null) {
            var image: THREE.Image = texture.image;

            if (image != null && image.width > 0) {
                canvas.title = texture.sourceFile;
                var scale: Float = canvas.width / image.width;

                if (texture.isDataTexture || texture.isCompressedTexture) {
                    var canvas2: HTMLCanvasElement = renderToCanvas(texture);
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

        this.texture = texture;
        return this;
    }

    public function setColorSpace(colorSpace: Int): UITexture {
        var texture: THREE.Texture = getValue();
        if (texture != null) {
            texture.colorSpace = colorSpace;
        }
        return this;
    }

    public function onChange(callback: () -> Void): UITexture {
        this.onChangeCallback = callback;
        return this;
    }
}

class UIOutliner extends UIDiv {
    public var selectedValue: Int;
    public var selectedIndex: Int;
    public var options: Array<Element>;

    public function new(editor: Editor) {
        super();

        this.dom.className = "Outliner";
        this.dom.tabIndex = 0;

        this.dom.addEventListener("keydown", (event: Event) -> {
            switch (event.code) {
                case "ArrowUp":
                case "ArrowDown":
                    event.preventDefault();
                    event.stopPropagation();
                    break;
            }
        });

        this.dom.addEventListener("keyup", (event: Event) -> {
            switch (event.code) {
                case "ArrowUp":
                    selectIndex(selectedIndex - 1);
                    break;
                case "ArrowDown":
                    selectIndex(selectedIndex + 1);
                    break;
            }
        });

        this.editor = editor;
        this.options = [];
        this.selectedIndex = -1;
        this.selectedValue = null;
    }

    public function selectIndex(index: Int) {
        if (index >= 0 && index < options.length) {
            setValue(options[index].value);
            var changeEvent: Event = new Event("change", { bubbles: true, cancelable: true });
            dom.dispatchEvent(changeEvent);
        }
    }

    public function setOptions(options: Array<Element>): UIOutliner {
        while (dom.children.length > 0) {
            dom.removeChild(dom.firstChild);
        }

        this.options = [];

        for (option in options) {
            option.className = "option";
            dom.appendChild(option);
            this.options.push(option);

            option.addEventListener("click", (event: Event) -> {
                setValue(option.value);
                var changeEvent: Event = new Event("change", { bubbles: true, cancelable: true });
                dom.dispatchEvent(changeEvent);
            });

            if (option.draggable) {
                var currentDrag: Element;

                option.addEventListener("drag", (event: Event) -> {
                    currentDrag = option;
                });

                option.addEventListener("dragstart", (event: Event) -> {
                    event.dataTransfer.setData("text", "foo");
                });

                option.addEventListener("dragover", (event: DragEvent) -> {
                    if (option == currentDrag) return;

                    var area: Float = event.offsetY / option.clientHeight;

                    if (area < 0.25) {
                        option.className = "option dragTop";
                    } else if (area > 0.75) {
                        option.className = "option dragBottom";
                    } else {
                        option.className = "option drag";
                    }
                });

                option.addEventListener("dragleave", (event: DragEvent) -> {
                    if (option == currentDrag) return;

                    option.className = "option";
                });

                option.addEventListener("drop", (event: DragEvent) -> {
                    if (option == currentDrag || currentDrag == null) return;

                    option.className = "option";

                    var object: THREE.Object3D = editor.scene.getObjectById(currentDrag.value);
                    var area: Float = event.offsetY / option.clientHeight;

                    if (area < 0.25) {
                        var nextObject: THREE.Object3D = editor.scene.getObjectById(option.value);
                        moveObject(object, nextObject.parent, nextObject);
                    } else if (area > 0.75) {
                        var nextObject: THREE.Object3D;
                        var parent: THREE.Object3D;

                        if (option.nextSibling != null) {
                            nextObject = editor.scene.getObjectById(option.nextSibling.value);
                            parent = nextObject.parent;
                        } else {
                            nextObject = null;
                            parent = editor.scene.getObjectById(option.value).parent;
                        }

                        moveObject(object, parent, nextObject);
                    } else {
                        var parentObject: THREE.Object3D = editor.scene.getObjectById(option.value);
                        moveObject(object, parentObject);
                    }
                });
            }
        }

        return this;
    }

    public function getValue(): Int {
        return selectedValue;
    }

    public function setValue(value: Int): UIOutliner {
        for (i in 0...options.length) {
            var element: Element = options[i];

            if (element.value == value) {
                element.classList.add("active");

                var y: Float = element.offsetTop - dom.offsetTop;
                var bottomY: Float = y + element.offsetHeight;
                var minScroll: Float = bottomY - dom.offsetHeight;

                if (dom.scrollTop > y) {
                    dom.scrollTop = y;
                } else if (dom.scrollTop < minScroll) {
                    dom.scrollTop = minScroll;
                }

                selectedIndex = i;
            } else {
                element.classList.remove("active");
            }
        }

        selectedValue = value;
        return this;
    }
}

class UIPoints extends UISpan {
    public var pointsList: UIDiv;
    public var pointsUI: Array<Dynamic>;
    public var lastPointIdx: Int;
    public var onChangeCallback: Null<() -> Void>;

    public function new() {
        super();

        dom.style.display = "inline-block";
        pointsList = new UIDiv();
        add(pointsList);

        pointsUI = [];
        lastPointIdx = 0;
        onChangeCallback = null;
    }

    public function onChange(callback: () -> Void): UIPoints {
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

    public function deletePointRow(idx: Int, dontUpdate: Bool = false) {
        if (pointsUI[idx] == null) return;

        pointsList.remove(pointsUI[idx].row);
        pointsUI.splice(idx, 1);

        if (!dontUpdate) {
            if (onChangeCallback != null) {
                onChangeCallback();
            }
        }

        lastPointIdx--;
    }
}

class UIPoints2 extends UIPoints {
    public function new() {
        super();

        var row: UIRow = new UIRow();
        add(row);

        var addPointButton: UIButton = new UIButton("+");
        addPointButton.onClick(() -> {
            if (pointsUI.length == 0) {
                pointsList.add(createPointRow(0, 0));
            } else {
                var point: Dynamic = pointsUI[pointsUI.length - 1];
                pointsList.add(createPointRow(point.x.getValue(), point.y.getValue()));
            }

            if (onChangeCallback != null) {
                onChangeCallback();
            }
        });
        row.add(addPointButton);
    }

    public function getValue(): Array<THREE.Vector2> {
        var points: Array<THREE.Vector2> = [];
        var count: Int = 0;

        for (i in 0...pointsUI.length) {
            var pointUI: Dynamic = pointsUI[i];

            if (pointUI == null) continue;

            points.push(new THREE.Vector2(pointUI.x.getValue(), pointUI.y.getValue()));
            count++;
            pointUI.lbl.setValue(count);
        }

        return points;
    }

    public function setValue(points: Array<THREE.Vector2>): UIPoints2 {
        clear();

        for (i in 0...points.length) {
            var point: THREE.Vector2 = points[i];
            pointsList.add(createPointRow(point.x, point.y));
        }

        if (onChangeCallback != null) {
            onChangeCallback();
        }

        return this;
    }

    public function createPointRow(x: Float, y: Float): UIDiv {
        var pointRow: UIDiv = new UIDiv();
        var lbl: UIText = new UIText(lastPointIdx + 1).setWidth("20px");
        var txtX: UINumber = new UINumber(x).setWidth("30px").onChange(() -> {
            if (onChangeCallback != null) {
                onChangeCallback();
            }
        });
        var txtY: UINumber = new UINumber(y).setWidth("30px").onChange(() -> {
            if (onChangeCallback != null) {
                onChangeCallback();
            }
        });

        var btn: UIButton = new UIButton("-");
        btn.onClick(() -> {
            if (isEditing) return;

            var idx: Int = pointsList.getIndexOfChild(pointRow);
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

        var row: UIRow = new UIRow();
        add(row);

        var addPointButton: UIButton = new UIButton("+");
        addPointButton.onClick(() -> {
            if (pointsUI.length == 0) {
                pointsList.add(createPointRow(0, 0, 0));
            } else {
                var point: Dynamic = pointsUI[pointsUI.length - 1];
                pointsList.add(createPointRow(point.x.getValue(), point.y.getValue(), point.z.getValue()));
            }

            if (onChangeCallback != null) {
                onChangeCallback();
            }
        });
        row.add(addPointButton);
    }

    public function getValue(): Array<THREE.Vector3> {
        var points: Array<THREE.Vector3> = [];
        var count: Int = 0;

        for (i in 0...pointsUI.length) {
            var pointUI: Dynamic = pointsUI[i];

            if (pointUI == null) continue;

            points.push(new THREE.Vector3(pointUI.x.getValue(), pointUI.y.getValue(), pointUI.z.getValue()));
            count++;
            pointUI.lbl.setValue(count);
        }

        return points;
    }

    public function setValue(points: Array<THREE.Vector3>): UIPoints3 {
        clear();

        for (i in 0...points.length) {
            var point: THREE.Vector3 = points[i];
            pointsList.add(createPointRow(point.x, point.y, point.z));
        }

        if (onChangeCallback != null) {
            onChangeCallback();
        }

        return this;
    }

    public function createPointRow(x: Float, y: Float, z: Float): UIDiv {
        var pointRow: UIDiv = new UIDiv();
        var lbl: UIText = new UIText(lastPointIdx + 1).setWidth("20px");
        var txtX: UINumber = new UINumber(x).setWidth("30px").onChange(() -> {
            if (onChangeCallback != null) {
                onChangeCallback();
            }
        });
        var txtY: UINumber = new UINumber(y).setWidth("30px").onChange(() -> {
            if (onChangeCallback != null) {
                onChangeCallback();
            }
        });
        var txtZ: UINumber = new UINumber(z).setWidth("30px").onChange(() -> {
            if (onChangeCallback != null) {
                onChangeCallback();
            }
        });

        var btn: UIButton = new UIButton("-");
        btn.onClick(() -> {
            if (isEditing) return;

            var idx: Int = pointsList.getIndexOfChild(pointRow);
            deletePointRow(idx);
        });

        pointsUI.push({ row: pointRow, lbl: lbl, x: txtX, y: txtY, z: txtZ });
        lastPointIdx++;
        pointRow.add(lbl, txtX, txtY, txtZ, btn);

        return pointRow;
    }
}

class UIBoolean extends UISpan {
    public var checkbox: UICheckbox;
    public var text: UIText;

    public function new(boolean: Bool, text: String) {
        super();

        setMarginRight("4px");

        checkbox = new UICheckbox(boolean);
        this.text = new UIText(text).setMarginLeft("3px");

        add(checkbox);
        add(this.text);
    }

    public function getValue(): Bool {
        return checkbox.getValue();
    }

    public function setValue(value: Bool): UIBoolean {
        checkbox.setValue(value);
        return this;
    }
}

var renderer: THREE.WebGLRenderer;
var fsQuad: Pass.FullScreenQuad;

function renderToCanvas(texture: THREE.Texture): HTMLCanvasElement {
    if (renderer == null) {
        renderer = new THREE.WebGLRenderer();
    }

    if (fsQuad == null) {
        fsQuad = new Pass.FullScreenQuad(new THREE.MeshBasicMaterial());
    }

    var image: THREE.Image = texture.image;

    renderer.setSize(image.width, image.height, false);

    fsQuad.material.map = texture;
    fsQuad.render(renderer);

    return renderer.domElement;
}

export { UITexture, UIOutliner, UIPoints, UIPoints2, UIPoints3, UIBoolean };