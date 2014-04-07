
module Util
  class << self
    # source: http://hamishrickerby.com/2008/05/31/mnemonic-password-generator-a-la-ruby/
    def generate_pw_string(letters=10, digits=6)
      consonants = "bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ"
      vowels = "aeiouAEIOU"
      password = ""
      (1..letters).each do |i|
        range = i%2 == 1 ? consonants : vowels
        password = password + range[rand(range.length), 1]
      end
      (1..digits).each do |i|
        password = password + rand(10).to_s
      end
      password
    end

    def generate_alnum_string(length=16)
      # don't use 0 or O ... too confusing
      Array.new(length){[*'1'..'9', *'a'..'z', *'A'..'N', *'P'..'Z'].sample}.join
    end
  end
end
