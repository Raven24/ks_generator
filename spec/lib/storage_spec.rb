
require 'spec_helper'

describe Storage do
  context 'uid' do
    it 'generates new uids' do
      u1 = Storage.next_uid
      u2 = Storage.next_uid

      expect(u1).not_to eql(u2)
    end

    it 'generates string uids' do
      expect(Storage.next_uid).to be_a(String)
    end
  end

  context 'save & retrieve' do
    it 'saves data' do
      expect { Storage.set('test', 'DATA') }.not_to raise_error
    end

    it 'retrieves data' do
      key = 'test'
      val = 'DATA'

      Storage.set(key, 'DATA')
      expect(Storage.get(key)).to eql(val)
    end

    it 'raises for unknown key' do
      expect { Storage.get('aaaa') }.to raise_error
    end
  end
end
