
class Storage
  class << self
    attr_reader :mutex

    def init!
      @mutex = Mutex.new
      @backend = Hash.new
    end

    def next_uid
      uid = Util.generate_alnum_string(8)
      mutex.synchronize do
        while has_key?(uid)
          uid = Util.generate_alnum_string(8)
        end
      end
      uid
    end

    def has_key?(key)
      @backend.has_key?(key)
    end

    def set(key, value)
      mutex.synchronize do
        @backend[key.to_s] = value
      end
    end

    def get(key)
      data = nil
      mutex.synchronize do
        raise unless @backend.has_key?(key.to_s)
        data = @backend[key.to_s]
      end
      data
    end

    def to_s
      @backend.to_s
    end
  end
end

Storage.init!
