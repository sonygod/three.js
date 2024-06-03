class Pipeline {

    public var cacheKey: String;
    public var usedTimes: Int;

    public function new(cacheKey: String) {

        this.cacheKey = cacheKey;
        this.usedTimes = 0;

    }

}