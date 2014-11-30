
module Helpers::Os
  def os_config
    os = params[:os] || settings.default_os
    file = File.join(settings.root, 'os', "#{os}.yml")
    Kickstart::OS.read_spec(file)
  end

  def passalgo_opts(name, data)
    radio_group(name, data['display_as'], data['values'].map.with_index { |opt, i|
      entry = (i==0) ? {checked: true} : {}
      entry.merge({ text: opt['display_as'], value: opt['value'] })
    })
  end

  def autopart_opts(name, data)
    radio_group(name, data['display_as'], data['values'].map.with_index { |opt, i|
      entry = (i==0) ? {checked: true} : {}
      entry.merge({ text: opt['display_as'], value: opt['value'] })
    })
  end

  def bootloader_opts(name, data)
    radio_group(name, data['display_as'], data['values'].map.with_index { |opt, i|
      entry = (i==0) ? {checked: true} : {}
      entry.merge({ text: opt['display_as'], value: opt['value'] })
    })
  end

  def firewall_opts(name, data)
    radio_group(name, data['display_as'], data['values'].map.with_index { |opt, i|
      entry = (i==0) ? {checked: true} : {}
      entry.merge({ text: opt['display_as'], value: opt['value'] })
    })
  end

  def repos_opts(title, data, name_ptrn)
    check_group(title, data.map.with_index { |opt, i|
      { text: opt['display_as'], name: (name_ptrn % opt['name']) }
    })
  end

  def selinux_opts(name, data)
    radio_group(name, data['display_as'], data['values'].map.with_index { |opt, i|
      entry = (i==0) ? {checked: true} : {}
      entry.merge({ text: opt['display_as'], value: opt['value'] })
    })
  end

  def package_opts(title, data, name_ptrn)
    check_group(title, data.map.with_index { |opt, i|
      { text: opt['display_as'], name: (name_ptrn % opt['value']) }
    })
  end
end
