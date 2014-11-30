
class Kickstart::Config

  ATTRIBUTES = [
    :install, :url, :auth, :user, :clearpart, :autopart, :bootloader, :firewall,
    :lang, :keyboard, :timezone, :selinux, :rootpw, :repo
  ]

  OPTIONS = [:pkg, :pre, :post]

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
    def from_hash(opts, os_spec)
      Kickstart::Config.new do |ks|
        ks.read_spec(os_spec)

        (ATTRIBUTES + OPTIONS).each do |attr|
          ks.send("set_#{attr}", opts[attr.to_s]) if opts.has_key?(attr.to_s)
        end
      end
    end
  end

  attr_accessor :spec, :options

  def initialize
    @options = {}
    @spec = {}
    yield self if block_given?
  end

  def read_spec(os_spec)
    @spec[:passalgo] = os_spec['options'].detect { |o|
      o['name'] == 'passalgo'
    }['values'].map { |o| o['value'] }

    @spec[:autopart] = os_spec['options'].detect { |o|
      o['name'] == 'autopart'
    }['values'].map { |o| o['value'] }

    @spec[:bootloader] = os_spec['options'].detect { |o|
      o['name'] == 'bootloader'
    }['values'].map { |o| o['value'] }

    @spec[:firewall] = os_spec['options'].detect { |o|
      o['name'] == 'firewall'
    }['values'].map { |o| o['value'] }

    @spec[:selinux] = os_spec['options'].detect { |o|
      o['name'] == 'selinux'
    }['values'].map { |o| o['value'] }

    @spec[:repos] = os_spec['repos'].each.with_object({}) { |r, hsh|
      hsh[r['name'].to_sym] = {
        name: r['name'],
        mirrorlist: r['mirrorlist'],
        include: r['include']
      }
    }

    @spec[:pkg_groups] = os_spec['pkg_groups'].map { |g| g['value'] }

    @spec[:pkgs] = os_spec['pkgs'].map { |p| p['value'] }
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
    @options[:auth][:passalgo] = opts['passalgo'] if @spec[:passalgo].include?(opts['passalgo'])
  end

  def set_user(opts)
    @options[:user] ||= []
    opts.each do |usr|
      usr[:'#plain_password'] = usr[:password]
      usr[:password] = Kickstart::PasswdUtil.crypt_pw(usr[:password])
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
    raise InvalidParameter unless @spec[:autopart].include?(opts['type'])
    @options[:autopart] = { type: opts['type'] }
  end

  def set_bootloader(opts)
    raise InvalidParameter unless @spec[:bootloader].include?(opts['location'])
    @options[:bootloader] = { location: opts['location'] }
  end

  def set_firewall(opt)
    raise InvalidParameter unless @spec[:firewall].include?(opt)
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
    raise InvalidParameter unless @spec[:selinux].include?(opt)
    @options[:selinux] ||= {}
    @options[:selinux][opt.to_sym] = true
  end

  def set_rootpw(opt)
    raise InvalidParameter if opt.empty?

    @options[:rootpw] ||= {}
    @options[:rootpw][:iscrypted] = true
    @options[:rootpw][:_] = Kickstart::PasswdUtil.crypt_pw(opt)
    @options[:rootpw][:'#plain_password'] = opt
  end

  def set_repo(opts)
    @options[:repo] ||= []
    opts.each do |k,v|
      @options[:repo] << @spec[:repos][k.to_sym] if @spec[:repos].has_key?(k.to_sym) &&
                                                  v == '1'
    end
  end

  def set_pkg(opts)
    @options[:pkg] = { groups: [], pkgs: [] }
    opts['groups'].each do |grp,v|
      next unless @spec[:pkg_groups].include?(grp)
      @options[:pkg][:groups] << grp if v == '1'
    end
    opts['pkgs'].each do |grp,v|
      next unless @spec[:pkgs].include?(grp)
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
