require 'sinatra/base'

require 'yaml'
require 'i18n'
require 'i18n/backend/fallbacks'
require File.join(File.dirname(__FILE__), 'lib', 'ks_generator')


class KsGenerator < Sinatra::Base
  configure do
    enable :sessions

    set :haml, format: :html5
    set :scss, views: File.join(settings.root, 'assets')

    set :default_os, 'centos_7'

    helpers Helpers::Form, Helpers::Snippet, Helpers::Os

    I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    I18n.load_path = Dir[File.join(settings.root, 'locales', '*.yml')]
    I18n.backend.load_translations
    I18n.default_locale = :en
  end

  configure(:development) do
    set :session_secret, 'test_devel_secret_very_mysterious_and_classified'
  end

  not_found do
    haml :'404', layout: :main_layout
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
    @os = os_config
    @version = Kickstart::Version.new @os['ks_ver']
    haml :index, layout: :main_layout
  end

  post '/create' do
    os = os_config
    ks_params = params[:ks]

    # set to install mode
    ks_params['install'] = true

    # specify install method 'url' pointing to the mirrorlist
    ks_params['url'] = {
      'mirrorlist' => os['mirrorlist']
    }

    # set root password
    ks_params['rootpw'] = Kickstart::PasswdUtil.generate_root_pw

    # configure what to do with existing partitions
    ks_params['clearpart'] = {
      'none' => '1',
      'initlabel' => '1'
    }

    # process users
    ks_params['user'] = params[:auth][:users].split("\n").map do |u|
      {name: u.strip, password: Kickstart::PasswdUtil.generate_user_pw }
    end

    # process ssh keys
    ks_params['sshkey'] = params[:auth][:sshkeys].split("\n").map do |k|
      parts = k.split(" ", 2).map(&:strip)
      # maps to nil, compact later
      next unless ks_params['user'].detect {|u| u[:name] == parts[0] }
      {username: parts[0], _: parts[1]}
    end.compact

    ks = Kickstart::Config.from_hash(ks_params, os)
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
    ks = Storage.get(uid) rescue halt(404)

    haml :show, layout: :main_layout, locals: {
      ks: ks.to_ks,
      uid: uid,
      users:  ks.users
    }
  end
end
