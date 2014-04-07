require 'sinatra/base'

require 'i18n'
require 'i18n/backend/fallbacks'

lib_dir = File.join(File.dirname(__FILE__), 'lib')

require File.join(lib_dir, 'util')
require File.join(lib_dir, 'kickstart_config')
require File.join(lib_dir, 'storage')

module FormHelpers
  def checkbox(name, text, checked=false, fmt=:haml)
    output = <<-END
%input{type: :hidden, name: '#{name}', value: 0 }
%label
  %input{type: :checkbox, name: '#{name}', value: 1, checked: #{(checked ? 'true' : 'false')} }
  #{text}
    END

    return output if fmt==:raw
    haml output
  end

  def check_group(text, options)
    check_options = options.map do |entry|
      checkbox(entry[:name], entry[:text], entry[:checked], :raw)
    end.join("\n")

    haml <<-END
%div.group_header
  #{text}

%div.columns
  #{check_options.split("\n").join("\n  ")}
    END
  end

  def radio_group(name, text, options)
    radio_options = options.map do |entry|
      <<-END
%label
  %input{type: :radio, name: '#{name}', value: '#{entry[:value]}', checked: #{(entry[:checked] ? 'true' : 'false')} }
  #{entry[:text]}
      END
    end.join("\n")

    haml <<-END
%div.group_header
  #{text}
#{radio_options}
    END
  end

  def dropdown(name, text, options)
    select_options = options.map do |entry|
      <<-END
    %option{value: '#{entry[:value]}', selected: #{entry[:selected] ? 'true' : 'false'} }
      #{entry[:text]}
      END
    end.join("\n")

    haml <<-END
%label
  #{text}
  %select{name: '#{name}'}
#{select_options}
    END
  end
end

module SnippetHelpers
  def snippet_title
    session.delete(:fresh) ? "Congratulations, we're done." : "Your Kickstart Config"
  end

  def password_list(usrs)
    usrs.map { |u| "#{u[:name].ljust(10)}: #{u[:password]}" }.join("\n")
  end
end

class KsGenerator < Sinatra::Base
  configure do
    enable :sessions

    set :haml, format: :html5
    set :scss, views: File.join(settings.root, 'assets')

    helpers FormHelpers, SnippetHelpers

    I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    I18n.load_path = Dir[File.join(settings.root, 'locales', '*.yml')]
    I18n.backend.load_translations
    I18n.default_locale = :en
  end

  configure(:development) do
    set :session_secret, 'test_devel_secret_very_mysterious_and_classified'
  end

  get '/assets/:name.:ext' do |name, ext|
    case ext
    when 'css'
      scss name.to_sym
    else
      raise 'unknown asset format'
    end
  end

  get '/' do
    haml :index, layout: :main_layout
  end

  post '/create' do
    ks_params = params[:ks]

    # set to install mode
    ks_params['install'] = true

    # specify install method 'url' pointing to the mirrorlist
    ks_params['url'] = {
      'mirrorlist' => 'http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch'
    }

    # set root password
    ks_params['rootpw'] = KickstartConfig.generate_root_pw

    # configure what to do with existing partitions
    ks_params['clearpart'] = {
      'none' => '1',
      'initlabel' => '1'
    }

    # process users
    ks_params['user'] = params[:auth][:users].split("\n").map do |u|
      {name: u.strip, password: KickstartConfig.generate_user_pw }
    end

    ks = KickstartConfig.from_hash(ks_params)
    uid = Storage.next_uid

    Storage.set(uid, ks)

    session[:fresh] = true
    redirect to("/#{uid}")
  end

  get '/:uid.cfg' do |uid|
    content_type 'text/plain'

    ks = Storage.get(uid)
    ks.to_ks
  end

  get '/:uid' do |uid|
    ks = Storage.get(uid)

    haml :show, layout: :main_layout, locals: {
      ks: ks.to_ks,
      uid: uid,
      users:  ks.users
    }
  end
end
