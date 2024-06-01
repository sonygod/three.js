import js.Browser;
import js.html.Element;

class MenubarView {

	public function new(editor: { signals: { offerXR: { dispatch(arg0: String): Void; }; enterXR: { dispatch(arg0: String): Void; }; }; strings: { getKey(arg0: String): String; }; }) {

		var container = new Element("div");
		container.className = "menu";

		var title = new Element("div");
		title.className = "title";
		title.textContent = editor.strings.getKey("menubar/view");
		container.appendChild(title);

		var options = new Element("div");
		options.className = "options";
		container.appendChild(options);

		// Fullscreen

		var optionFullscreen = new Element("div");
		optionFullscreen.className = "option";
		optionFullscreen.textContent = editor.strings.getKey("menubar/view/fullscreen");
		optionFullscreen.onclick = function(_) {
			if (Browser.document.fullscreenElement == null) {
				Browser.document.documentElement.requestFullscreen();
			} else if (Browser.document.exitFullscreen != null) {
				Browser.document.exitFullscreen();
			}

			// Safari
			if (Browser.document.webkitFullscreenElement == null) {
				Browser.document.documentElement.webkitRequestFullscreen();
			} else if (Browser.document.webkitExitFullscreen != null) {
				Browser.document.webkitExitFullscreen();
			}
		}
		options.appendChild(optionFullscreen);

		// XR (Work in progress)

		if (Reflect.hasField(Browser.navigator, "xr")) {
			var navigatorXR: Dynamic = Browser.navigator.xr;
			if (Reflect.hasField(navigatorXR, "offerSession")) {
				editor.signals.offerXR.dispatch("immersive-ar");
			} else {
				navigatorXR.isSessionSupported("immersive-ar").then(function(supported: Bool) {
					if (supported) {
						var optionAR = new Element("div");
						optionAR.className = "option";
						optionAR.textContent = "AR";
						optionAR.onclick = function(_) {
							editor.signals.enterXR.dispatch("immersive-ar");
						};
						options.appendChild(optionAR);
					} else {
						navigatorXR.isSessionSupported("immersive-vr").then(function(supported: Bool) {
							if (supported) {
								var optionVR = new Element("div");
								optionVR.className = "option";
								optionVR.textContent = "VR";
								optionVR.onclick = function(_) {
									editor.signals.enterXR.dispatch("immersive-vr");
								};
								options.appendChild(optionVR);
							}
						});
					}
				});
			}
		}

		this.container = container;
	}

	public var container: Element;
}