require 'bundler'
Bundler.require

configure do
  set :sessions, secret: ENV['SECRET']
end

require './model'

=begin
root :to => "index#list"
match 'feed', controller: :index, action: :list, format: :rss
match 'home' => "home#edit"
match 'auth' => "sessions#auth"
match ':controller(/:action(/:id(.:format)))'
match ':id', :controller => :index, :action => :user, :id => :id
=end

get '/feed' do
end

get '/home' do
  @user = User.find(session[:login_user_id]) rescue nil
  redirect '/auth' and return if @user.nil?
  haml :home
end

post '/home' do
  @user = User.find(session[:login_user_id]) rescue nil
  @user.post = params[:message]
  @user.account = params[:account]
  @user.font_color = params[:font_color]
  @user.save
  @user.background_images.destroy_all
  params[:images].split("\n").each{|x|
    BackgroundImage.create user_id: @user.id, url: x
  }
  @user.tweet if ENV['RACK_ENV'] == 'production'
  redirect '/home'
end

get '/auth' do
  url = "http://#{request.host_with_port}/sessions/callback"
  request_token = User.new.consumer.get_request_token(:oauth_callback => url)
  session[:request_token] = request_token.token
  session[:request_token_secret] = request_token.secret
  redirect request_token.authorize_url
end

get '/sessions/callback' do
  request_token = OAuth::RequestToken.new(User.new.consumer, session[:request_token], session[:request_token_secret])
  @access_token = request_token.get_access_token({}, :oauth_token => params[:oauth_token], :oauth_verifier => params[:oauth_verifier])
  Twitter.configure do |config|
    config.consumer_key = User::KEY
    config.consumer_secret = User::SECRET
    config.oauth_token = @access_token.token
    config.oauth_token_secret = @access_token.secret
  end

  info = Twitter.user(@access_token.params[:screen_name].to_s)
  user = User.where(:screen_name => info.screen_name).first rescue nil
  user = User.new if user.nil?
  user.twitter_id = info.id.to_s
  user.screen_name = info.screen_name.to_s
  user.name = info.name.to_s
  user.icon = info.profile_image_url
  user.token = @access_token.token
  user.secret = @access_token.secret
  user.created_at = Time.now
  user.save
  session[:login_user_id] = user.id
  redirect '/home'
end

get '/favicon.ico' do
end

get '/:id' do
  @user = User.where(:screen_name => params[:id]).first
  haml :user
end

get '/' do
  @users = User.order("updated_at desc").limit(50).offset((page-1)*50)
  haml :index
end

helpers do
  def page
    i = params[:page] ? params[:page].to_i : 0
    i < 1 ? 1 : i
  end
end
