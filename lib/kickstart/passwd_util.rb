
class Kickstart::PasswdUtil
  class << self
    def crypt_pw(pass)
      salt = Util.generate_alnum_string(16)
      pass.crypt("$6$#{salt}")
    end

    def generate_root_pw(letters=6, digits=3)
      Util.generate_pw_string(letters, digits)
    end

    def generate_user_pw(letters=5, digits=2)
      Util.generate_pw_string(letters, digits)
    end
  end
end
