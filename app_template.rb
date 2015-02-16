# アプリ名の取得
@app_name = app_name

# clean file
run 'rm README.rdoc'

# .gitignore
run 'gibo OSX Ruby Rails JetBrains SASS SublimeText > .gitignore' rescue nil
gsub_file '.gitignore', /^config\/initializers\/secret_token.rb$/, ''
gsub_file '.gitignore', /config\/secret.yml/, ''

# Gemfile
gsub_file 'Gemfile', /#.*?\n/, ''
gsub_file 'Gemfile', /\n+/, "\n"
gsub_file 'Gemfile', /^gem\s\'sqlite3\'/, 'gem \'mysql2\''
gsub_file 'Gemfile', /^gem\s\'turbolinks\'/, ''
append_file 'Gemfile', <<-CODE
# Bootstrap & Bootswatch & font-awesome
gem 'bootstrap-sass'
gem 'bootswatch-rails'
gem 'font-awesome-rails'
gem 'therubyracer', platforms: :ruby
gem 'unicorn'
# Slim
gem 'slim-rails'
# Assets log cleaner
gem 'quiet_assets'
# Form Builders
gem 'simple_form'
# HTML5 Validator
gem 'html5_validators'
# Action Args
gem 'action_args'
# PG/MySQL Log Formatter
gem 'rails-flog'
# Pagenation
gem 'kaminari'
# NewRelic
gem 'newrelic_rpm'
# HTML Parser
gem 'nokogiri'
# Hash extensions
gem 'hashie'
# Settings
gem 'settingslogic'
# Cron Manage
gem 'whenever', require: false
# Presenter Layer Helper
gem 'active_decorator'
group :development do
  gem 'html2slim'
  # N+1問題の検出
  gem 'bullet'
  # Rack Profiler
  # gem 'rack-mini-profiler'
  # Deploy
  gem 'capistrano', '~> 3.2.1'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'capistrano-bundler'
  gem 'capistrano3-unicorn'
end
group :development, :test do
  gem 'annotate'
  # Pry & extensions
  gem 'pry-rails'
  gem 'pry-coolline'
  gem 'pry-byebug'
  gem 'rb-readline'
  # PryでのSQLの結果を綺麗に表示
  gem 'hirb'
  gem 'hirb-unicode'
  # pryの色付けをしてくれる
  gem 'awesome_print'
  # Rspec
  gem 'rspec-rails'
  gem 'spring-commands-rspec'
  gem 'guard-rspec'
  gem 'rb-fsevent'
  # test fixture
  gem 'factory_girl_rails'
  # テスト環境のテーブルをきれいにする
  gem 'database_rewinder'
  # Time Mock
  gem 'timecop'
end
group :test do
  gem 'shoulda-matchers'
end
CODE

# install gems
run 'bundle install --path vendor/bundle --jobs=4'

# secret
gsub_file 'config/secrets.yml', /<\%\=\sENV\["SECRET_KEY_BASE"\]\s\%>/, `bundle exec rake secret`

# Database
run 'rm -rf config/database.yml'
run 'touch config/database.yml'
append_file 'config/database.yml', %(
  default: &default
    adapter: mysql2
    encoding: utf8
    pool: 5
    timeout: 5000
    charset: utf8
    collation: utf8_general_ci
    username: root

  development:
    <<: *default
    database: #{@app_name}_development

  test:
    <<: *default
    database: #{@app_name}_test

  production:
    database: #{@app_name}_production
)
run 'bundle exec rake db:create'

# set config/application.rb
application  do
  %q{
    # Set timezone
    config.time_zone = 'Tokyo'
    config.active_record.default_timezone = :local
    # 日本語化
    I18n.enforce_available_locales = true
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja
    # generatorの設定
    config.generators do |g|
      g.orm :active_record
      g.template_engine :slim
      g.test_framework  :rspec, :fixture => true
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
      g.view_specs false
      g.controller_specs true
      g.routing_specs false
      g.helper_specs false
      g.request_specs false
      g.assets false
      g.helper false
    end
    # libファイルの自動読み込み
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
  }
end

# For Bullet (N+1 Problem)
insert_into_file 'config/environments/development.rb',%(
  # Bulletの設定
  config.after_initialize do
    Bullet.enable = true # Bulletプラグインを有効
    Bullet.alert = true # JavaScriptでの通知
    Bullet.bullet_logger = true # log/bullet.logへの出力
    Bullet.console = true # ブラウザのコンソールログに記録
    Bullet.rails_logger = true # Railsログに出力
  end
), after: 'config.assets.debug = true'

# set Japanese locale
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/'

# erb to slim
run 'bundle exec erb2slim -d app/views'
gsub_file 'app/views/layouts/application.html.slim', /,\s\'data-turbolinks-track\'\s=>\strue/, ''

# do not use turbolinks
gsub_file 'app/assets/javascripts/application.js', /\/\/=\srequire\sturbolinks\n/, ''

# Bootstrap
run 'rm -f app/assets/stylesheets/application.css'
run 'touch app/assets/stylesheets/application.css.scss'
append_file 'app/assets/stylesheets/application.css.scss', %q(
  // First import cerulean variables
  @import "bootswatch/yeti/variables";
  @import "bootstrap-custom.scss";

  *{
    // borderとpaddingをボックス内に含めるようにする
    box-sizing: border-box;
    // 長押しポップアップメニューの非表示
    -webkit-touch-callout:none;
  }

  html, body{
    width: 100%;
    height: 100%;
    margin: 0;
    padding: 0;
  }

  body{
    padding-top: 60px;
  }

  @import "bootswatch/yeti/bootswatch";
  @import "font-awesome";
)
run 'touch app/assets/stylesheets/bootstrap-custom.scss'
append_file 'app/assets/stylesheets/bootstrap-custom.scss', %q(
// Core variables and mixins
@import "bootstrap/variables";
@import "bootstrap/mixins";

// Reset and dependencies
@import "bootstrap/normalize";
@import "bootstrap/print";
@import "bootstrap/glyphicons";

// Core CSS
@import "bootstrap/scaffolding";
@import "bootstrap/type";
@import "bootstrap/code";
@import "bootstrap/grid";
@import "bootstrap/tables";
@import "bootstrap/forms";
@import "bootstrap/buttons";

// Components
// @import "bootstrap/component-animations";
// @import "bootstrap/dropdowns";
@import "bootstrap/button-groups";
@import "bootstrap/input-groups";
@import "bootstrap/navs";
@import "bootstrap/navbar";
// @import "bootstrap/breadcrumbs";
// @import "bootstrap/pagination";
// @import "bootstrap/pager";
// @import "bootstrap/labels";
// @import "bootstrap/badges";
// @import "bootstrap/jumbotron";
// @import "bootstrap/thumbnails";
// @import "bootstrap/alerts";
// @import "bootstrap/progress-bars";
// @import "bootstrap/media";
// @import "bootstrap/list-group";
// @import "bootstrap/panels";
// @import "bootstrap/responsive-embed";
// @import "bootstrap/wells";
// @import "bootstrap/close";

// Components w/ JavaScript
// @import "bootstrap/modals";
// @import "bootstrap/tooltip";
// @import "bootstrap/popovers";
// @import "bootstrap/carousel";

// Utility classes
// @import "bootstrap/utilities";
// @import "bootstrap/responsive-utilities";
)

# Simple Form
generate 'simple_form:install --bootstrap'

# Whenever
run 'bundle exec wheneverize .'

# Capistrano
run 'touch Capfile'
append_file 'Capfile',%(
  require 'capistrano/setup'
  require 'capistrano/deploy'
  require 'capistrano/rbenv'
  require 'capistrano/bundler'
  require 'capistrano/rails/assets'
  require 'capistrano/rails/migrations'
  require 'capistrano3/unicorn'
  require "whenever/capistrano"
  Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
)
run 'touch config/deploy.rb'
append_file 'config/deploy.rb', <<-CODE
set :application, #{@app_name}
set :repo_url, 'git@github.com:Iwark/#{@app_name}.git'

set :scm, :git

set :rbenv_ruby, '2.2.0'

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/secrets.yml}

set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/assets public/uploads}

set :default_stage, "production"

set :whenever_identifier, ->{ "\#{fetch(:application)}_\#{fetch(:stage)}" }

set :bundle_env_variables, { 'NOKOGIRI_USE_SYSTEM_LIBRARIES' => 1 }

# set :linked_dirs, (fetch(:linked_dirs) + ['tmp/pids'])

set :unicorn_rack_env, "production"
set :unicorn_config_path, 'config/unicorn.rb'

namespace :deploy do

  desc 'Restart application'
  task :restart do
    invoke 'unicorn:restart'
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      within release_path do
        with rails_env: fetch(:rails_env) do
          # execute :rake, 'cache:clear'
        end
      end
    end
  end

end
CODE
run 'mkdir config/deploy'
run 'touch config/deploy/production.rb'
append_file 'config/deploy/production.rb', <<-CODE
role :app, %w{#{@app_name}}
role :web, %w{#{@app_name}}
role :db,  %w{#{@app_name}}

set :stage, :production
set :rails_env, :production

set :deploy_to, '/home/ec2-user/#{@app_name}'

set :default_env, {
  rbenv_root: "/home/ec2-user/.rbenv",
  path: "/home/ec2-user/.rbenv/shims:/home/ec2-user/.rbenv/bin:$PATH",
}
CODE

# Setting Logic
run 'touch config/application.yml'
append_file 'config/application.yml', <<-CODE
defaults: &defaults


development:
  <<: *defaults


test:
  <<: *defaults


staging:
  <<: *defaults


production:
  <<: *defaults
CODE
run 'touch config/initializers/0_settings.rb'
append_file 'config/initializers/0_settings.rb', <<-CODE
class Settings < Settingslogic
  source "\#{Rails.root}/config/application.yml"
  namespace Rails.env
end
CODE

# Kaminari config
generate 'kaminari:config'

# Unicorn
run 'touch config/unicorn.rb'
append_file 'config/unicorn.rb', %q(
  listen '/tmp/unicorn.sock', :backlog => 64
  pid "tmp/pids/unicorn.pid"

  stderr_path File.expand_path('unicorn.log', File.dirname(__FILE__) + '/../log')
  stdout_path File.expand_path('unicorn.log', File.dirname(__FILE__) + '/../log')

  worker_processes 2

  before_exec do |server|
    ENV['BUNDLE_GEMFILE'] = File.expand_path('Gemfile', ENV['RAILS_ROOT'])
  end

  preload_app true

  before_fork do |server, worker|
    defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

    old_pid = "\#{ server.config[:pid] }.oldbin"
    if File.exists?(old_pid) && server.pid != old_pid
      begin
        sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
        Process.kill sig, File.read(old_pid).to_i
      rescue Errno::ENOENT, Errno::ESRCH
      end
    end
  end
)

# Rspec
generate 'rspec:install'
run "echo '--color -f d' > .rspec"

# Guard
run 'touch Guardfile'
append_file 'Guardfile', <<-EOS
  guard :rspec, cmd: 'spring rspec' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/\#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb')  { "spec" }

    # Rails example
    watch(%r{^app/(.+)\.rb$})                           { |m| "spec/\#{m[1]}_spec.rb" }
    watch(%r{^app/(.*)(\.erb|\.haml|\.slim)$})          { |m| "spec/\#{m[1]}\#{m[2]}_spec.rb" }
    watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/\#{m[1]}_routing_spec.rb", "spec/\#{m[2]}s/\#{m[1]}_\#{m[2]}_spec.rb", "spec/acceptance/\#{m[1]}_spec.rb"] }
    watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
    watch('config/routes.rb')                           { "spec/routing" }
    watch('app/controllers/application_controller.rb')  { "spec/controllers" }
    watch('spec/rails_helper.rb')                       { "spec" }

    # Capybara features specs
    watch(%r{^app/views/(.+)/.*\.(erb|haml|slim)$})     { |m| "spec/features/\#{m[1]}_spec.rb" }

    # Turnip features and steps
    watch(%r{^spec/acceptance/(.+)\.feature$})
    watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$})   { |m| Dir[File.join("**/\#{m[1]}.feature")][0] || 'spec/acceptance' }
  end
EOS

# git
git :init
git add: '.'
git commit: "-a -m 'first commit'"
