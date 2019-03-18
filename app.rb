require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'mysql2'
require 'mysql2-cs-bind'
require 'pry'


enable :sessions

# MySQLドライバの設定
client = Mysql2::Client.new(
    host: 'localhost',
    port: 3306,
    username: 'root',
    passward: '',
    database: 'CODEBASE_Sinatra',
    reconnect: true,
)




#　ユーザーがアカウントを持っているか確認
def check_user
  if session[:user_id].nil?
    redirect '/login'
  end
end

#　どのユーザーか確認
def set_user(client)
  return nil if session[:user_id].nil?
  @user = client.xquery("SELECT * FROM users WHERE id = ?", session[:user_id]).to_a.first
end


#　ログイン
get '/login' do

  erb :login, :layout => nil
end

post '/login' do
  name = params[:name]
  password = params[:password]

  user = client.xquery("SELECT * FROM users WHERE name = ? and password = ?", [ name,password]).to_a.first

  if user
    session[:user_id] = user['id']

    flash[:login] = "Welcome #{name}!"

    redirect '/'
  else
    erb :login,:layout => nil
  end
end


# 新規ユーザー登録
post'/signup' do

  name = params[:name]
  email = params[:email]
  password = params[:password]

  client.xquery('INSERT INTO users (name, email,password) VALUES(?,?,?)',[name, email, password])
  session[:user_id] = client.last_id


  flash[:login] = "Welcome #{name}!"


  redirect '/'
end


# TopPage
get '/' do
  set_user(client)
  check_user

  @DB = client

  # postsに投稿データを挿入！
  posts = client.xquery('SELECT * FROM posts')

  # いいね機能
  posts.each do |post|
    count = client.xquery("SELECT * FROM likes where post_id = ?", post['id'])
    post['likes']= count.size

  end

  @posts=posts


  erb :index, :layout => :layout
end


#画像投稿画面
get '/create' do
  set_user(client)

  erb :create
end


post '/create' do
  set_user(client)

  # 画像情報を取得
  @filename = params[:file][:filename]
  file = params[:file][:tempfile]

  # 画像情報を取得
  File.open("./public/img/#{@filename}",'wb') do |f|
    f.write(file.read)
  end

  # 投稿を新規作成
  # @user['name']をpostsのuser_nameに格納
  query ='INSERT INTO posts (user_id,user_name,title, description, image_path, created_at, updated_at)VALUES(?,?,?,?,?,CURRENT_TIMESTAMP(),CURRENT_TIMESTAMP())'
  client.xquery(query,@user['id'],@user['name'],params[:title], params[:description],"/img/#{@filename}")

  flash[:created] = "Created!"

  # トップページにリダイレクト
  redirect to('/')
end


# 投稿詳細画面
get '/show/:id' do
  check_user
  set_user(client)

  @post = client.xquery('SELECT * FROM posts WHERE id = ?',params[:id]).first

  @comments = client.xquery('SELECT * FROM comments WHERE post_id = ?',params[:id])

  erb :show, :layout => :layout

end


#Comment作成
# show/:id のページに留まるためにpost '/show/:id/comment'にする
post '/show/:id/comment' do
  set_user(client)

  id = params[:id]

  @post = client.xquery('SELECT * FROM posts WHERE id = ?', id).first

  # Commentを新規作成
  query ='INSERT INTO comments (user_name, body, created_at,post_id)VALUES(?,?,CURRENT_TIMESTAMP(),?)'
  client.xquery(query,@user['name'],params[:comment],params[:id])

  redirect to("/show/#{id}")
end



#ユーザーページ
get '/home' do
  check_user
  set_user(client)

  # ログインしているユーザーの投稿画像表示
  @home_user = client.xquery('SELECT posts.id,title,description,image_path,created_at FROM users INNER JOIN posts ON users.id = posts.user_id WHERE users.id = ?',@user['id'])

  @save = client.xquery('SELECT * FROM save WHERE user_id = ?',@user['id'])


  erb :home, :layout => :layout
end


# Logout
get '/logout' do
  set_user(client)
  erb :logout, :layout => :layout
end


post '/logout' do
  session[:user_id] = nil
  redirect '/login'
end


#　投稿の削除
delete '/destroy/:id' do
  set_user(client)

  query = 'DELETE FROM posts WHERE id = ?'
  client.xquery(query, params[:id])

  flash[:deleted] = "Deleted!"

  redirect to('/home')
end

#　保存
post '/save/:id' do
  set_user(client)

  id = params[:id]

  @post = client.xquery('SELECT * FROM posts WHERE id = ?', id).first

  query = 'INSERT INTO save(user_id,post_id,post_title,image_path)VALUES(?,?,?,?)'
  client.xquery(query,@user['id'],params[:id],@post['title'],@post['image_path'])

  flash[:save] = "Save!"

  redirect to("/show/#{id}")

end

#いいね
post '/like/:id/create' do
  set_user(client)
  id = params[:id]

  @post = client.xquery('SELECT * FROM posts WHERE id = ?', id).first
  # binding.pry

  query = 'INSERT INTO likes(post_id,user_id)VALUES(?,?)'
  client.xquery(query, id,@user['id'])



  redirect to('/')
end

# いいね取り消し
post '/like/:id/delete' do
  set_user(client)
  id = params[:id]

  @post = client.xquery('SELECT * FROM posts WHERE id = ?', id).first

  query = 'DELETE FROM likes WHERE user_id = ? AND post_id = ?'
  client.xquery(query,@user['id'],params[:id])

  redirect to('/')
end

get '/topic' do
  set_user(client)

  # postsに投稿データを挿入！
  posts = client.xquery('SELECT * FROM posts')

  # いいね機能
  posts.each do |post|
    count = client.xquery("SELECT * FROM likes where post_id = ?", post['id'])
    post['likes']= count.size

    # Topic
    # if post['likes'] >= 3
    #   query = 'INSERT INTO topics(post_id,post_title,image_path,)VALUES(?,?,?)'
    #   client.xquery(query,post['id'],post['title'],post['image_path'])
    # end

  end

  @posts = posts



  erb :topic, :layout => :layout
end

post '/like/topic/:id/create' do
  set_user(client)
  id = params[:id]

  @post = client.xquery('SELECT * FROM posts WHERE id = ?', id).first
  # binding.pry

  query = 'INSERT INTO likes(post_id,user_id)VALUES(?,?)'
  client.xquery(query, id,@user['id'])

  redirect to ('/topic')
end

post '/like/topic/:id/delete' do
  set_user(client)
  id = params[:id]

  @post = client.xquery('SELECT * FROM posts WHERE id = ?', id).first

  query = 'DELETE FROM likes WHERE user_id = ? AND post_id = ?'
  client.xquery(query,@user['id'],params[:id])

  redirect to('/topic')
end


# post '/search' do
#   set_user(client)
#   search = params[:search]
#
#   sql = "SELECT * FROM posts WHERE title LIKE '#{search}'"
#
#   @search = sql
#
#   erb :search, :layout => :layout
# end