class Pipeline {

	public var cacheKey: String;

	public var usedTimes: Int = 0;

	public function new(cacheKey: String) {
		this.cacheKey = cacheKey;
	}

}