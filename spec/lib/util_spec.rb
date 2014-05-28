
require 'spec_helper'

describe Util do
  it 'generates password strings' do
    str = Util.generate_pw_string
    expect(str).to match(/[a-zA-Z]{10}[0-9]{6}/)
  end

  it 'generates alpha-numerical strings' do
    str = Util.generate_alnum_string
    expect(str).to match(/[a-zA-Z0-9]{16}/)
  end
end
