ENV['GOOGLE_AUTH_DOMAIN'] = 'noxqslabs.nl'
# ENV['GOOGLE_AUTH_DOMAIN'] = 'gmail.com'

require 'sinatra'
require 'sinatra/google-auth'
# require 'sinatra/reloader' if development?
require 'mongoid'
require 'slim'
require 'sass'
require 'redcarpet'

case
  when production?
    set port: 8081
  when development?
    set port: 4567
    require 'sinatra/reloader'
    require 'better_errors'
    use BetterErrors::Middleware
    BetterErrors.application_root = File.dirname(File.realpath(__FILE__))
end
 
configure do
  Mongoid.load!("./config/mongoid.yml")
  enable :sessions

  set :session_secret, '*&(^B234'

  Slim::Engine.set_default_options pretty: true, sort_attrs: false
end

helpers do
  def admin?
    session[:admin]
  end

  def users?
    session[:users]
  end

  def admin_protected!
    halt 401,"You are not authorized to delete or edit this page!" unless admin?
  end

  def protected!
    halt 401,"You are not authorized to see this page!" unless users?
  end

  def url_for page
    if admin?
      "/pages/" + page.id
    else
      "/" + page.permalink  
    end 
  end

end

class Page
  include Mongoid::Document
 
  field :title,   type: String
  field :content, type: String
  field :permalink, type: String, default: -> { make_permalink }

  def make_permalink
    title.downcase.gsub(/[\W]/, '-').squeeze('-').chomp('-') if title
  end
end

get '/' do
  redirect to('/pages')
end

get '/:permalink' do
  begin
    @page = Page.find_by(permalink: params[:permalink])
  rescue
    pass
  end
  slim :show
end

get('/styles/main.css'){ scss :styles }

get '/login' do
  authenticate
  if session['user'] == "remcovanhest@noxqslabs.nl"
    session[:admin]=true
  end
  session[:users]=true
  redirect back
end

get '/logout' do
  session['user']=nil
  session[:users]=nil
  session[:admin]=nil
  redirect back
end

get '/pages' do
  @pages = Page.all
  @title = "Simple CMS: Page List"
  @user = session['user']
  if admin?
    @user = "Admin: "+session['user']
  end
  slim :index
end

post '/pages' do
  protected!
  page = Page.create(params[:page])
  redirect to("/pages/#{page.id}")
end

get '/pages/new' do
  protected!
  @page = Page.new
  slim :new
end

get '/pages/:id/edit' do
  admin_protected!
  @page = Page.find(params[:id])
  slim :edit
end

get '/pages/delete/:id' do
  admin_protected!
  @page = Page.find(params[:id])
  slim :delete
end

put '/pages/:id' do
  admin_protected!
  page = Page.find(params[:id])
  page.update_attributes(params[:page])
  redirect to("/pages/#{page.id}")
end

get '/pages/:id' do
  @page = Page.find(params[:id])
  @title = @page.title
  slim :show
end

delete '/pages/:id' do
  admin_protected!
  Page.find(params[:id]).destroy
  redirect to('/pages')
end
