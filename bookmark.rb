require "sinatra"
require "sinatra/reloader"

require "tilt/erubis"
require "sinatra/content_for"

require_relative "database_persistence"

request_nbr = 1

MY_DEBUG_7 = false
def mputs(str, num_tabs=0)
  if MY_DEBUG_7
    indent = ""
    (num_tabs).times do
      indent += "  "
    end
    puts indent + str
  end 
end

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

before  do

  mputs ""
  mputs "#{request_nbr} ****************************************************************"
  mputs ""
  request_nbr += 1

  mputs "params = #{params}", 1

  # puts "Request Environment #{ request.env }"
 
  # mputs "Routing to #{request.path_info}"
  # mputs "request.request_method = #{request.request_method}"

  mputs "Routing to: #{request.request_method.downcase} \"#{request.path_info}\"", 1
  mputs ""

  # mputs "request.class = #{request.class}"    # Sinatra::Request
  
  @storage = DatabasePersistence.new(logger) # logger is provided by Sinatra
end

helpers do
end

def merb(label)
  mputs "Rendering #{label}.erb", 2
  mputs ""

  erb label
end

def mredirect(route)
  mputs "Redirecting to #{route}", 2
  mputs ""
  redirect route
end

def msession_message(out_message)
  mputs "Session message: #{out_message}", 2
  session[:message] = out_message
end

def user_signed_in?
  session.key?(:username)
end

def require_signed_in_user
  unless user_signed_in?
    msession_message "You must be signed in to do that."
    mredirect "/"
  end
end

# Display all urls, along with choices: edit and New Document.
get "/" do
  num_tabs = 2

  @user_urls = {}

  if user_signed_in?
    @user_urls = @storage.get_user_urls(session[:username])
  end

  mputs "In get /. @user_urls = #{@user_urls}", num_tabs
  
  merb :index
end

get "/new" do
  require_signed_in_user
  merb :new
end

post "/addurl" do
  num_tabs = 2

  mputs "In post /addurl.  sign_in params[:url].to_s = #{params[:url].to_s}", num_tabs
  require_signed_in_user

  url = params[:url].to_s
  mputs "In post /addurl. new url = #{url}", num_tabs

  if url.size == 0
    msession_message "A non-zero length url is required."
    status 422
    merb :new
  else

    @storage.relate_user_and_url(session[:username], url)

    mredirect "/"
  end
end

get "/users/createaccount" do
  mputs "In get /users/createaccount", 2
  merb :createaccount
end

post "/users/createaccount" do
  num_tabs = 2
  mputs "In post /users/createaccount  params[:username] = #{params[:username]}", num_tabs

  username = params[:username]

  mputs "In post /users/createaccount  username = #{username}", num_tabs

  if @storage.username_available?(username)
    mputs "In post /users/createaccount  username is available", num_tabs

    @storage.store_new_username(username)
    session[:username] = username

    msession_message "Thanks for creating a new account (and signing in)!"
    mredirect "/"
  else
    msession_message "User name not available"
    status 422
    merb :createaccount
  end
end

get "/users/signin" do
  mputs "In get /users/signin", 2

  merb :signin
end

post "/users/signin" do

  username = params[:username]

  if @storage.username_exists?(username)
    session[:username] = username
    msession_message "Welcome!"
    mredirect "/"
  else
    msession_message "Invalid username"
    # msession_message "Invalid credentials"
    status 422
    merb :signin
  end
end

post "/users/signout" do
  session.delete(:username)
  msession_message("You have been signed out.")
  # session[:message] = "You have been signed out."
  mredirect "/"
end

post "/users/deleteaccount" do
  mputs "post \"/users/deleteaccount\"", 2

  @storage.delete_account(session[:username])

  session.delete(:username)
  msession_message("You have deleted your account (and you have signed out).")

  # session[:message] = "You have deleted your account (and you have signed out)."
  mredirect "/"
end

# Delete a url
post "/:url_key/delete_url" do
  mputs "post \"/:url_key/delete_url\"", 2

  num_tabs = 2
  mputs "In post /:url_key/delete_url  params[:url] = #{params[:url_key]}", num_tabs
  require_signed_in_user

  index = params[:url_key].to_i

  deleted_url = @storage.delete_url(index, session[:username])

  msession_message "#{deleted_url} has been deleted."
  mredirect "/"
end

