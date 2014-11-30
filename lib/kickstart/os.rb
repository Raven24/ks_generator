
class Kickstart::OS
  class << self
    def read_spec(os)
      data = YAML.load_file(os)
      Kickstart::OS.new(data)
    end
  end

  def initialize(data)
    @data = data
  end

  def [](key)
    @data[key]
  end

  def to_s
    @data['name']
  end
end
