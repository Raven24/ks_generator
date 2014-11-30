
require 'spec_helper'

describe Kickstart::PasswdUtil do
  context '#crypt_pw' do
    before do
      allow(Util).to receive(:generate_alnum_string) { "salt_string" }
    end

    it 'encrypts a given password with salt string' do
      pwd = Kickstart::PasswdUtil.crypt_pw("test123!$&")
      expect(pwd).to include("salt_string")
    end
  end

  context '#generate_root_pw' do
    it 'generates a password string' do
      expect(Kickstart::PasswdUtil.generate_root_pw).to match(/[a-z]{6}[0-9]{3}/i)
    end
  end

  context '#generate_user_pw' do
    it 'generates a password string' do
      expect(Kickstart::PasswdUtil.generate_root_pw).to match(/[a-z]{5}[0-9]{2}/i)
    end
  end
end
