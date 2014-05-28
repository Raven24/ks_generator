
class Kickstart::Config

  ATTRIBUTES = [
    :install, :url, :auth, :user, :clearpart, :autopart, :bootloader, :firewall,
    :lang, :keyboard, :timezone, :selinux, :rootpw, :repo
  ]

  OPTIONS = [:pkg, :pre, :post]

  KNOWN_REPOS = {
    rpmfusion_free: {
      name:'RPMFusionFree',
      mirrorlist:'http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-$releasever&arch=$basearch',
      include:'rpmfusion-free-release'
    },
    rpmfusion_free_updates: {
      name:'RPMFusionFreeUpdates',
      mirrorlist:'http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-$releasever&arch=$basearch',
      include:'rpmfusion-free-release'
    },
    rpmfusion_nonfree: {
      name:'RPMFusionNonFree',
      mirrorlist:'http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-$releasever&arch=$basearch',
      include:'rpmfusion-nonfree-release'
    },
    rpmfusion_nonfree_updates: {
      name:'RPMFusionNonFreeUpdates',
      mirrorlist:'http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-$releasever&arch=$basearch',
      include:'rpmfusion-nonfree-release'
    },
  }

  OPTS_SELINUX = ['enforcing', 'permissive', 'disabled']

  OPTS_FIREWALL = ['disabled', 'enabled']

  OPTS_BOOTLOADER = ['mbr', 'partition', 'none']

  OPTS_AUTOPART = ['lvm', 'btrfs', 'thinp', 'plain']

  OPTS_PASSALGO = ['sha256', 'sha512']

  KNOWN_PKG_GROUPS = [
    'c-development', 'development-tools', 'development-libs', 'firefox',
    'ruby', 'python', 'perl', 'php', 'admin-tools', 'system-tools',
    'kde-desktop', 'gnome-desktop', 'mysql', 'mongodb', 'standard',
    'virtualization', 'sql-server'
  ]

  KNOWN_PKGS = [
    'wget','acpid','curl','vim','screen','mc','git','htop','openssh-clients',
    'redis', 'mariadb-devel', 'nodejs', 'postfix'
  ]

  KNOWN_TIMEZONES = [
    'Africa/Cairo', 'Africa/Dakar', 'Africa/Johannesburg', 'America/Chicago',
    'America/Costa_Rica', 'America/New York', 'Asia/Tokyo', 'Asia/Baghdad',
    'Asia/Bangkok', 'Asia/Dubai', 'Australia/Sydney', 'Europe/Amsterdam',
    'Europe/Kiev', 'Europe/Moscow', 'Europe/Rome', 'Europe/Vienna', 'Europe/Zurich',
    'Pacific/Honolulu', ''
  ]

  KNOWN_LANGUAGES = [
    'de_DE', 'de_AT', 'en_US', 'en_GB', 'es_ES', 'fr_FR'
  ]

  class << self
    def from_hash(opts)
      Kickstart::Config.new do |ks|
        (ATTRIBUTES + OPTIONS).each do |attr|
          ks.send("set_#{attr}", opts[attr.to_s]) if opts.has_key?(attr.to_s)
        end
      end
    end

    def crypt_pw(password)
      salt = Util.generate_alnum_string(16)
      password.crypt("$6$#{salt}")
    end

    def generate_root_pw(letters=6, digits=3)
      Util.generate_pw_string(letters, digits)
    end

    def generate_user_pw(letters=5, digits=2)
      Util.generate_pw_string(letters, digits)
    end
  end

  attr_accessor :options

  def initialize
    @options = {}
    yield self if block_given?
  end

  def set_install(opt)
    raise InvalidParameter unless opt
    @options[:install] = true
  end

  def set_url(opt)
    raise InvalidParameter unless opt.has_key?('mirrorlist')
    @options[:url] = { mirrorlist: opt['mirrorlist'] }
  end

  def set_auth(opts)
    @options[:auth] ||= {}
    @options[:auth][:useshadow] = true if opts['useshadow'] == '1'
    @options[:auth][:passalgo] = opts['passalgo'] if OPTS_PASSALGO.include?(opts['passalgo'])
  end

  def set_user(opts)
    @options[:user] ||= []
    opts.each do |usr|
      usr[:'#plain_password'] = usr[:password]
      usr[:password] = Kickstart::Config.crypt_pw(usr[:password])
      usr[:iscrypted] = true

      @options[:user] << usr if (usr[:name] =~ /^[a-z0-9\_\-]{3,}$/i)
    end
  end

  def set_clearpart(opts)
    @options[:clearpart] = {}
    @options[:clearpart][:none] = true if opts['none'] == '1'
    @options[:clearpart][:initlabel] = true if opts['initlabel'] == '1'
  end


  def set_autopart(opts)
    raise InvalidParameter unless OPTS_AUTOPART.include?(opts['type'])
    @options[:autopart] = { type: opts['type'] }
  end

  def set_bootloader(opts)
    raise InvalidParameter unless OPTS_BOOTLOADER.include?(opts['location'])
    @options[:bootloader] = { location: opts['location'] }
  end

  def set_firewall(opt)
    raise InvalidParameter unless OPTS_FIREWALL.include?(opt)
    @options[:firewall] ||= {}
    @options[:firewall][opt.to_sym] = true
  end

  def set_lang(opt)
    raise InvalidParameter unless KNOWN_LANGUAGES.include?(opt)
    @options[:lang] = "#{opt}.UTF8"
  end

  def set_keyboard(opt)
    raise InvalidParameter unless ['us', 'de'].include?(opt)
    @options[:keyboard] = opt
  end

  def set_timezone(opts)
    @options[:timezone] ||= {}
    @options[:timezone][:utc] = true if opts['utc'] == '1'
    @options[:timezone][:_] = opts['_'] if KNOWN_TIMEZONES.include?(opts['_'])
  end

  def set_selinux(opt)
    raise InvalidParameter unless OPTS_SELINUX.include?(opt)
    @options[:selinux] ||= {}
    @options[:selinux][opt.to_sym] = true
  end

  def set_rootpw(opt)
    raise InvalidParameter if opt.empty?

    @options[:rootpw] ||= {}
    @options[:rootpw][:iscrypted] = true
    @options[:rootpw][:_] = Kickstart::Config.crypt_pw(opt)
    @options[:rootpw][:'#plain_password'] = opt
  end

  def set_repo(opts)
    @options[:repo] ||= []
    opts.each do |k,v|
      @options[:repo] << KNOWN_REPOS[k.to_sym] if KNOWN_REPOS.has_key?(k.to_sym) &&
                                                  v == '1'
    end
  end

  def set_pkg(opts)
    @options[:pkg] = { groups: [], pkgs: [] }
    opts['groups'].each do |grp,v|
      next unless KNOWN_PKG_GROUPS.include?(grp)
      @options[:pkg][:groups] << grp if v == '1'
    end
    opts['pkgs'].each do |grp,v|
      next unless KNOWN_PKGS.include?(grp)
      @options[:pkg][:pkgs] << grp if v == '1'
    end
  end

  [:pre, :post].each do |sec|
    define_method "set_#{sec}" do |opt|
      return if opt.empty?
      @options[:pre] = Util::clean_lineendings(opt)
    end
  end

  def set_post(opt)
    return if opt.empty?
    @options[:post] = Util::clean_lineendings(opt)
  end

  def users
    ([ {name: 'root', password: @options[:rootpw][:'#plain_password']} ] +
     @options[:user].map { |u| { name: u[:name], password: u[:'#plain_password'] } } )
  end

  def to_ks
    [ '# Kickstart Configuration',
      ks_options,
      '# Packages',
      pkg_list,
      '# Pre-install script',
      ks_script(:pre),
      '# Post-install script',
      ks_script(:post)
    ].join("\n\n")
  end

  def ks_options
    ATTRIBUTES.map do |attr|
      case @options[attr]
      when Array
        @options[attr].map do |entry|
          make_cmd(attr, entry)
        end
      else
        make_cmd(attr, @options[attr])
      end
    end.flatten.compact.join("\n")
  end

  def make_cmd(cmd, params)
    case params
    when true
      cmd.to_s
    when String
      "#{cmd} #{params}"
    when Hash
      cmd = [cmd]
      params.each do |k,v|
        if v==true
          cmd << "--#{k}"
        elsif k==:_
          cmd << v
        elsif k.to_s.start_with?('#')
          # noop
        elsif v.is_a?(String)
          cmd << "--#{k}=#{v}"
        end
      end
      cmd.join(' ')
    end
  end

  def pkg_list
     (['%packages'] +
      @options[:pkg][:groups].map { |grp| "@#{grp}" } +
      ['']+
      @options[:pkg][:pkgs]+
      ['%end']).join("\n")
  end

  def ks_script(section)
    raise InvalidParameter unless [:pre, :post].include?(section)
    return '' if !@options[section] || @options[section].empty?

    sec_cmd = section
    sec_cmd = make_cmd(section, {log: '/root/ks-post.log'}) if section == :post

    ["%#{sec_cmd}",
     @options[section],
     '%end'].join("\n")
  end

  class InvalidParameter < StandardError; end
end
