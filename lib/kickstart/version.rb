
class Kickstart::Version
  VERSION_REGEX = /([A-Z]{1,4})([0-9]{1,2})/
  def initialize(version)
    VERSION_REGEX.match(version) do |md|
      @version_key = md[1]
      @version_num = md[2].to_i
    end
  end

  def at_least?(other)
    VERSION_REGEX.match(other) do |md|
      return (md[1] == @version_key &&
             md[2].to_i <= @version_num)
    end
  end

  def at_most?(other)
    VERSION_REGEX.match(other) do |md|
      return (md[1] == @version_key &&
             md[2].to_i >= @version_num)
    end
  end

  def to_s
    "#{@version_key}#{@version_num}"
  end
end
