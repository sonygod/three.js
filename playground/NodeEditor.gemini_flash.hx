import three.THREE;
import three.nodes.Nodes;
import flow.Canvas;
import flow.CircleMenu;
import flow.ButtonInput;
import flow.StringInput;
import flow.ContextMenu;
import flow.Tips;
import flow.Search;
import flow.Loader;
import flow.Node;
import flow.TreeViewNode;
import flow.TreeViewInput;
import flow.Element;
import node_editor.editors.FileEditor;
import node_editor.NodeEditorUtils;
import node_editor.NodeEditorLib;
import node_editor.SplitscreenManager;

class NodeEditor extends three.EventDispatcher {

	public var scene:THREE.Scene = null;
	public var renderer:THREE.WebGLRenderer = null;
	public var composer:THREE.EffectComposer = null;
	public var canvas:Canvas;
	public var domElement:HtmlElement;
	public var nodeClasses:Array<Dynamic> = [];
	public var _preview:Bool = false;
	public var _splitscreen:Bool = false;
	public var _wasSplitscreen:Bool = false;
	public var search:Search = null;
	public var menu:CircleMenu = null;
	public var previewMenu:CircleMenu = null;
	public var nodesContext:ContextMenu = null;
	public var examplesContext:ContextMenu = null;
	public var tips:Tips = null;
	public var splitview:SplitscreenManager = null;

	public function new(scene:THREE.Scene = null, renderer:THREE.WebGLRenderer = null, composer:THREE.EffectComposer = null) {
		super();

		domElement = new HtmlElement("flow");
		canvas = new Canvas();

		domElement.appendChild(canvas.dom);

		this.scene = scene;
		this.renderer = renderer;
		this.composer = composer;

		var global = Nodes.global;

		global.set("THREE", THREE);
		global.set("TSL", Nodes);

		global.set("scene", scene);
		global.set("renderer", renderer);
		global.set("composer", composer);

		_initSplitview();
		_initUpload();
		_initTips();
		_initMenu();
		_initSearch();
		_initNodesContext();
		_initExamplesContext();
		_initShortcuts();
		_initParams();
	}

	public function setSize(width:Int, height:Int):NodeEditor {
		canvas.setSize(width, height);
		return this;
	}

	public function centralizeNode(node:Node):NodeEditor {
		var canvas = this.canvas;
		var nodeRect = node.dom.getBoundingClientRect();

		node.setPosition((canvas.width / 2 - canvas.scrollLeft) - nodeRect.width, (canvas.height / 2 - canvas.scrollTop) - nodeRect.height);

		return this;
	}

	public function add(node:Node):NodeEditor {
		var onRemove = function() {
			node.removeEventListener("remove", onRemove);
			node.setEditor(null);
		};

		node.setEditor(this);
		node.addEventListener("remove", onRemove);

		canvas.add(node);

		dispatchEvent({ type: "add", node: node });

		return this;
	}

	public function get nodes():Array<Node> {
		return canvas.nodes;
	}

	public function set preview(value:Bool) {
		if (_preview == value) return;

		if (value) {
			_wasSplitscreen = splitscreen;
			splitscreen = false;

			menu.dom.remove();
			canvas.dom.remove();
			search.dom.remove();

			domElement.appendChild(previewMenu.dom);
		} else {
			canvas.focusSelected = false;

			domElement.appendChild(menu.dom);
			domElement.appendChild(canvas.dom);
			domElement.appendChild(search.dom);

			previewMenu.dom.remove();

			if (_wasSplitscreen == true) {
				splitscreen = true;
			}
		}

		_preview = value;
	}

	public function get preview():Bool {
		return _preview;
	}

	public function set splitscreen(value:Bool) {
		if (_splitscreen == value) return;

		splitview.setSplitview(value);

		_splitscreen = value;
	}

	public function get splitscreen():Bool {
		return _splitscreen;
	}

	public function newProject() {
		var canvas = this.canvas;
		canvas.clear();
		canvas.scrollLeft = 0;
		canvas.scrollTop = 0;
		canvas.zoom = 1;

		dispatchEvent({ type: "new" });
	}

	public function loadURL(url:String):Void {
		var loader = new Loader(Loader.OBJECTS);
		loader.load(url, NodeEditorLib.ClassLib).then(json => {
			loadJSON(json);
		});
	}

	public function loadJSON(json:Dynamic) {
		var canvas = this.canvas;

		canvas.clear();

		canvas.deserialize(json);

		for (node in canvas.nodes) {
			add(node);
		}

		dispatchEvent({ type: "load" });
	}

	private function _initSplitview() {
		splitview = new SplitscreenManager(this);
	}

	private function _initUpload() {
		var canvas = this.canvas;

		canvas.onDrop(function() {
			for (item in canvas.droppedItems) {
				var relativeClientX = canvas.relativeClientX;
				var relativeClientY = canvas.relativeClientY;

				var file = item.getAsFile();
				var reader = new FileReader();

				reader.onload = function(e:FileEvent) {
					var fileEditor = new FileEditor(e.target.result, file.name);

					fileEditor.setPosition(relativeClientX - (fileEditor.getWidth() / 2), relativeClientY - 20);

					add(fileEditor);
				};

				reader.readAsArrayBuffer(file);
			}
		});
	}

	private function _initTips() {
		tips = new Tips();

		domElement.appendChild(tips.dom);
	}

	private function _initMenu() {
		menu = new CircleMenu();
		previewMenu = new CircleMenu();

		menu.setAlign("top left");
		previewMenu.setAlign("top left");

		var previewButton = new ButtonInput().setIcon("ti ti-brand-threejs").setToolTip("Preview");
		var splitscreenButton = new ButtonInput().setIcon("ti ti-layout-sidebar-right-expand").setToolTip("Splitscreen");
		var menuButton = new ButtonInput().setIcon("ti ti-apps").setToolTip("Add");
		var examplesButton = new ButtonInput().setIcon("ti ti-file-symlink").setToolTip("Examples");
		var newButton = new ButtonInput().setIcon("ti ti-file").setToolTip("New");
		var openButton = new ButtonInput().setIcon("ti ti-upload").setToolTip("Open");
		var saveButton = new ButtonInput().setIcon("ti ti-download").setToolTip("Save");

		var editorButton = new ButtonInput().setIcon("ti ti-subtask").setToolTip("Editor");

		previewButton.onClick(function() {
			preview = true;
		});
		editorButton.onClick(function() {
			preview = false;
		});

		splitscreenButton.onClick(function() {
			splitscreen = !splitscreen;
			splitscreenButton.setIcon(splitscreen ? "ti ti-layout-sidebar-right-collapse" : "ti ti-layout-sidebar-right-expand");
		});

		menuButton.onClick(function() {
			nodesContext.open();
		});
		examplesButton.onClick(function() {
			examplesContext.open();
		});

		newButton.onClick(function() {
			if (js.Lib.confirm("Are you sure?") == true) {
				newProject();
			}
		});

		openButton.onClick(function() {
			var input = new HtmlElement("input");
			input.type = "file";

			input.onchange = function(e:FileEvent) {
				var file = e.target.files[0];

				var reader = new FileReader();
				reader.readAsText(file, "UTF-8");

				reader.onload = function(readerEvent:FileEvent) {
					var loader = new Loader(Loader.OBJECTS);
					var json = loader.parse(js.Lib.JSON.parse(readerEvent.target.result), NodeEditorLib.ClassLib);

					loadJSON(json);
				};
			};

			input.click();
		});

		saveButton.onClick(function() {
			NodeEditorUtils.exportJSON(canvas.toJSON(), "node_editor");
		});

		menu.add(previewButton).add(splitscreenButton).add(newButton).add(examplesButton).add(openButton).add(saveButton).add(menuButton);

		previewMenu.add(editorButton);

		domElement.appendChild(menu.dom);

		this.menu = menu;
		this.previewMenu = previewMenu;
	}

	private function _initExamplesContext() {
		examplesContext = new ContextMenu();

		var onClickExample = function(button:ButtonInput) {
			examplesContext.hide();

			var filename = button.getExtra();

			loadURL("./examples/" + filename + ".json");
		};

		var addExamples = function(category:String, names:Array<String>) {
			var subContext = new ContextMenu();

			for (name in names) {
				var filename = name.replace(" ", "-").toLowerCase();

				subContext.add(new ButtonInput(name).setIcon("ti ti-file-symlink").onClick(onClickExample).setExtra(category.toLowerCase() + "/" + filename));
			}

			context.add(new ButtonInput(category), subContext);

			return subContext;
		};

		addExamples("Basic", ["Teapot", "Matcap", "Fresnel", "Particles"]);

		this.examplesContext = context;
	}

	private function _initShortcuts() {
		js.Lib.document.addEventListener("keydown", function(e:KeyboardEvent) {
			if (e.target == js.Lib.document.body) {
				var key = e.key;

				if (key == "Tab") {
					search.inputDOM.focus();

					e.preventDefault();
					e.stopImmediatePropagation();
				} else if (key == " ") {
					preview = !preview;
				} else if (key == "Delete") {
					if (canvas.selected != null) canvas.selected.dispose();
				} else if (key == "Escape") {
					canvas.select(null);
				}
			}
		});
	}

	private function _initParams() {
		var urlParams = new URLSearchParams(js.Lib.window.location.search);

		var example = urlParams.get("example") || "basic/teapot";

		loadURL("./examples/" + example + ".json");
	}

	public function addClass(nodeData:Dynamic):NodeEditor {
		removeClass(nodeData);

		nodeClasses.push(nodeData);

		NodeEditorLib.ClassLib[nodeData.name] = nodeData.nodeClass;

		return this;
	}

	public function removeClass(nodeData:Dynamic):NodeEditor {
		var index = nodeClasses.indexOf(nodeData);

		if (index != -1) {
			nodeClasses.splice(index, 1);
			Reflect.deleteField(NodeEditorLib.ClassLib, nodeData.name);
		}

		return this;
	}

	private function _initSearch() {
		var traverseNodeEditors = function(item:Dynamic) {
			if (item.children != null) {
				for (subItem in item.children) {
					traverseNodeEditors(subItem);
				}
			} else {
				var button = new ButtonInput(item.name);
				button.setIcon("ti ti-" + item.icon);
				button.addEventListener("complete", function() {
					NodeEditorLib.getNodeEditorClass(item).then(nodeClass => {
						var node = new nodeClass();
						add(node);
						centralizeNode(node);
						canvas.select(node);
					});
				});

				search.add(button);

				if (item.tags != null) {
					search.setTag(button, item.tags);
				}
			}
		};

		search = new Search();
		search.forceAutoComplete = true;

		search.onFilter(function() {
			search.clear();

			NodeEditorLib.getNodeList().then(nodeList => {
				for (item in nodeList.nodes) {
					traverseNodeEditors(item);
				}

				for (item in nodeClasses) {
					traverseNodeEditors(item);
				}
			});
		});

		search.onSubmit(function() {
			if (search.currentFiltered != null) {
				search.currentFiltered.button.dispatchEvent(new Event("complete"));
			}
		});

		this.search = search;

		domElement.appendChild(search.dom);
	}

	private function _initNodesContext() {
		var context = new ContextMenu(canvas.canvas).setWidth(300);

		var isContext = false;
		var contextPosition = {x:0, y:0};

		var add = function(node:Node) {
			context.hide();

			add(node);

			if (isContext) {
				node.setPosition(Math.round(contextPosition.x), Math.round(contextPosition.y));
			} else {
				centralizeNode(node);
			}

			canvas.select(node);

			isContext = false;
		};

		context.onContext(function() {
			isContext = true;

			var relativeClientX = canvas.relativeClientX;
			var relativeClientY = canvas.relativeClientY;

			contextPosition.x = Math.round(relativeClientX);
			contextPosition.y = Math.round(relativeClientY);
		});

		context.addEventListener("show", function() {
			reset();
			focus();
		});

		var nodeButtons = new Array<TreeViewNode>();

		var nodeButtonsVisible = new Array<TreeViewNode>();
		var nodeButtonsIndex = -1;

		var focus = function() {
			js.Lib.requestAnimationFrame(function() {
				search.inputDOM.focus();
			});
		};
		var reset = function() {
			search.setValue("", false);

			for (button in nodeButtons) {
				button.setOpened(false).setVisible(true).setSelected(false);
			}
		};

		var node = new Node();
		context.add(node);

		var search = new StringInput().setPlaceHolder("Search...").setIcon("ti ti-list-search");

		search.inputDOM.addEventListener("keydown", function(e:KeyboardEvent) {
			var key = e.key;

			if (key == "ArrowDown") {
				var previous = nodeButtonsVisible[nodeButtonsIndex];
				if (previous != null) previous.setSelected(false);

				var current = nodeButtonsVisible[nodeButtonsIndex = (nodeButtonsIndex + 1) % nodeButtonsVisible.length];
				if (current != null) current.setSelected(true);

				e.preventDefault();
				e.stopImmediatePropagation();
			} else if (key == "ArrowUp") {
				var previous = nodeButtonsVisible[nodeButtonsIndex];
				if (previous != null) previous.setSelected(false);

				var current = nodeButtonsVisible[nodeButtonsIndex > 0 ? --nodeButtonsIndex : (nodeButtonsIndex = nodeButtonsVisible.length - 1)];
				if (current != null) current.setSelected(true);

				e.preventDefault();
				e.stopImmediatePropagation();
			} else if (key == "Enter") {
				if (nodeButtonsVisible[nodeButtonsIndex] != null) {
					nodeButtonsVisible[nodeButtonsIndex].dom.click();
				} else {
					context.hide();
				}

				e.preventDefault();
				e.stopImmediatePropagation();
			} else if (key == "Escape") {
				context.hide();
			}
		});

		search.onChange(function() {
			var value = search.getValue().toLowerCase();

			if (value.length == 0) return reset();

			nodeButtonsVisible = [];
			nodeButtonsIndex = 0;

			for (button in nodeButtons) {
				var buttonLabel = button.getLabel().toLowerCase();

				button.setVisible(false).setSelected(false);

				var visible = buttonLabel.indexOf(value) != -1;

				if (visible && button.children.length == 0) {
					nodeButtonsVisible.push(button);
				}
			}

			for (button in nodeButtonsVisible) {
				var parent = button;

				while (parent != null) {
					parent.setOpened(true).setVisible(true);

					parent = parent.parent;
				}
			}

			if (nodeButtonsVisible[nodeButtonsIndex] != null) {
				nodeButtonsVisible[nodeButtonsIndex].setSelected(true);
			}
		});

		var treeView = new TreeViewInput();
		node.add(new Element().setHeight(30).add(search));
		node.add(new Element().setHeight(200).add(treeView));

		var addNodeEditorElement = function(nodeData:Dynamic):TreeViewNode {
			var button = new TreeViewNode(nodeData.name);
			button.setIcon("ti ti-" + nodeData.icon);

			if (nodeData.children == null) {
				button.isNodeClass = true;
				button.onClick(function() {
					NodeEditorLib.getNodeEditorClass(nodeData).then(nodeClass => {
						add(new nodeClass());
					});
				});
			}

			if (nodeData.tip != null) {
				//button.setToolTip(item.tip);
			}

			nodeButtons.push(button);

			if (nodeData.children != null) {
				for (subItem in nodeData.children) {
					var subButton = addNodeEditorElement(subItem);

					button.add(subButton);
				}
			}

			return button;
		};

		NodeEditorLib.getNodeList().then(nodeList => {
			for (node in nodeList.nodes) {
				var button = addNodeEditorElement(node);

				treeView.add(button);
			}

			this.nodesContext = context;
		});
	}
}