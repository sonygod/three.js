class LoadingManager {
    var onStart: Function;
    var onLoad: Function;
    var onProgress: Function;
    var onError: Function;
    var itemStart: Function;
    var itemEnd: Function;
    var itemError: Function;
    var resolveURL: Function;
    var setURLModifier: Function;
    var addHandler: Function;
    var removeHandler: Function;
    var getHandler: Function;

    private var isLoading: Bool = false;
    private var itemsLoaded: Int = 0;
    private var itemsTotal: Int = 0;
    private var urlModifier: Function;
    private var handlers: Array<Dynamic> = [];

    public function new(onLoad: Function, onProgress: Function, onError: Function) {
        this.onLoad = onLoad;
        this.onProgress = onProgress;
        this.onError = onError;

        this.itemStart = function(url: String): Void {
            itemsTotal ++;

            if (!isLoading && onStart != null) {
                onStart(url, itemsLoaded, itemsTotal);
            }

            isLoading = true;
        };

        this.itemEnd = function(url: String): Void {
            itemsLoaded ++;

            if (onProgress != null) {
                onProgress(url, itemsLoaded, itemsTotal);
            }

            if (itemsLoaded === itemsTotal) {
                isLoading = false;

                if (onLoad != null) {
                    onLoad();
                }
            }
        };

        this.itemError = function(url: String): Void {
            if (onError != null) {
                onError(url);
            }
        };

        this.resolveURL = function(url: String): String {
            return urlModifier != null ? urlModifier(url) : url;
        };

        this.setURLModifier = function(transform: Function): LoadingManager {
            urlModifier = transform;
            return this;
        };

        this.addHandler = function(regex: EReg, loader: Dynamic): LoadingManager {
            handlers.push(regex, loader);
            return this;
        };

        this.removeHandler = function(regex: EReg): LoadingManager {
            var index = handlers.indexOf(regex);

            if (index !== -1) {
                handlers.splice(index, 2);
            }

            return this;
        };

        this.getHandler = function(file: String): Dynamic {
            for (var i = 0; i < handlers.length; i += 2) {
                var regex = cast handlers[i];
                var loader = handlers[i + 1];

                if (regex.global) regex.lastIndex = 0;

                if (regex.match(file)) {
                    return loader;
                }
            }

            return null;
        };
    }
}

var DefaultLoadingManager: LoadingManager = new LoadingManager(null, null, null);