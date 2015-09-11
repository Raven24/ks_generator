
KS_DIR = File.join(LIB_DIR, 'kickstart')

module Kickstart
  require File.join(KS_DIR, 'version')
  require File.join(KS_DIR, 'passwd_util')
  require File.join(KS_DIR, 'config')
  require File.join(KS_DIR, 'os')
end
