import js.Browser.window;
import js.html.HtmlElement;
import js.html.HtmlVideoElement;

class VideoPlayer extends HtmlElement {
    private _video: HtmlVideoElement;

    public function new() {
        super();
        this._video = window.document.createElement("video") as HtmlVideoElement;
        this.setElement(this._video);
    }

    public function play() {
        this._video.play();
    }

    public function pause() {
        this._video.pause();
    }

    public function stop() {
        this._video.pause();
        this._video.currentTime = 0;
    }

    public function get muted():Bool {
        return this._video.muted;
    }

    public function set muted(value:Bool) {
        this._video.muted = value;
    }

    public function get autoplay():Bool {
        return this._video.autoplay;
    }

    public function set autoplay(value:Bool) {
        this._video.autoplay = value;
    }

    public function get loop():Bool {
        return this._video.loop;
    }

    public function set loop(value:Bool) {
        this._video.loop = value;
    }

    public function get currentTime():Float {
        return this._video.currentTime;
    }

    public function set currentTime(seconds:Float) {
        this._video.currentTime = seconds;
    }

    public function get duration():Float {
        return this._video.duration;
    }

    public function set src(url:String) {
        this._video.src = url;
    }
}