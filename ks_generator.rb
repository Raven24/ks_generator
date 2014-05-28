require 'sinatra/base'

require 'i18n'
require 'i18n/backend/fallbacks'
require File.join(File.dirname(__FILE__), 'lib', 'ks_generator')


class KsGenerator < Sinatra::Base
  configure do
    enable :sessions

    set :haml, format: :html5
    set :scss, views: File.join(settings.root, 'assets')

    helpers Helpers::Form, Helpers::Snippet

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
    ks_params['rootpw'] = Kickstart::Config.generate_root_pw

    # configure what to do with existing partitions
    ks_params['clearpart'] = {
      'none' => '1',
      'initlabel' => '1'
    }

    # process users
    ks_params['user'] = params[:auth][:users].split("\n").map do |u|
      {name: u.strip, password: Kickstart::Config.generate_user_pw }
    end

    ks = Kickstart::Config.from_hash(ks_params)
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
