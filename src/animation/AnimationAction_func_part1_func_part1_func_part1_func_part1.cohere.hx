import js.Browser.window;
import js.html.HtmlElement;
import js.html.HtmlVideoElement;

class VideoPlayer extends HtmlElement {
    public function new(videoId: String) {
        super(window.document.getElementById(videoId));
    }

    public function play() {
        untyped __js__("play");
    }

    public function pause() {
        untyped __js__("pause");
    }

    public function stop() {
        untyped __js__("pause");
        untyped __js__("currentTime", 0);
    }

    public function get_paused():Bool {
        return untyped __js__("paused");
    }

    public function set_paused(value:Bool) {
        untyped __js__("paused", value);
    }

    public function get_ended():Bool {
        return untyped __js__("ended");
    }

    public function get_volume():Float {
        return untyped __js__("volume");
    }

    public function set_volume(value:Float) {
        untyped __js__("volume", value);
    }

    public function get_currentTime():Float {
        return untyped __js__("currentTime");
    }

    public function set_currentTime(value:Float) {
        untyped __js__("currentTime", value);
    }

    public function get_duration():Float {
        return untyped __js__("duration");
    }
}

class VideoRecorder extends HtmlVideoElement {
    public function new() {
        super();
    }

    public function startRecording() {
        untyped __js__("record");
    }

    public function stopRecording() {
        untyped __js__("stop");
    }

    public function saveRecording(filename: String) {
        untyped __js__("save", filename);
    }
}