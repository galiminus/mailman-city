require 'sinatra'
require 'builder'
require 'pony'
require 'tmail'
require 'nokogiri'
require 'crypt/rijndael'
require 'yaml'
require 'uri'
require 'escape'
require 'pathname'

config = YAML.load_file("config.yaml")
config.each do |key, value|
  eval("$#{key}='#{value}'")
end

$aes = Crypt::Rijndael.new($aes_key)

class MLServer
  def places
    places = []
    Dir.open("#{$mailman_dir}/lists").each do |file|
      match = file.match(/(.+)\.#{$domain}/)
      places << Place.new(match[1]) if match
    end
    return places
  end
end

class Place
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def lists
    lists = []
    name = Escape.shell_command(@name)
    `cd '#{$mailman_dir}' && bin/list_lists -V #{name}`.split("\n").each do |line|
      match = line.match(/([a-z]+)\@/)
      lists << List.new(match[1], "#{name}.#{$domain}") if match
    end
    return lists    
  end
end

class List
  include Comparable

  attr_reader :name, :host

  def List.email?(email)
    TMail::Address.parse(email)
    true
  rescue
    false
  end

  def initialize(name, host)
    @name = name
    @host = host
  end

  def <=>(other)
    @name <=> other.name
  end

  def ==(other)
    @host = other.host and @name == other.name
  end

  def members
    members = []
    list = Escape.shell_command("#{@name}@#{@host}")
    `cd '#{$mailman_dir}' && bin/list_members #{list}`.split("\n").each do |line|
      members << line
    end
    return members
  end

  def subscribe(email)
    list = Escape.shell_command("#{@name}@#{host}")
    `cd '#{$mailman_dir}' && echo #{Escape.shell_command(email)} | bin/add_members -w n -r - #{list}`
  end

  def unsubscribe(email)
    list = Escape.shell_command("#{@name}@#{host}")
    `cd '#{$mailman_dir}' && echo #{Escape.shell_command(email)} | bin/remove_members -n -f - #{list}`
  end
end

def load_xhtml(path)
  path = Pathname.new(path).cleanpath.to_s
  if (path =~ /^views\/archives\//)
    raw = File.open(path).read
    raw.gsub!('<UL>', '<li><ul class="sublist">')
    raw.gsub!('</UL>', '</ul></li>')
    raw.gsub!('</I>', '</i>')
    raw.gsub!('<LI>', '<li>')
    raw.gsub!('<A HREF', '<a href')
    raw.gsub!('</A>', '</a>')
    raw.gsub!('<PRE>', '<pre class="text">')
    raw.gsub!('</PRE>', '</pre>')
    raw.gsub!("Previous message:", "")
    raw.gsub!("Next message:", "")
    return raw
  end
end

def send_confirm(place, lists, email, subscribe)
  aes_code = $aes.encrypt_string({'place' => place.name,
                                  'lists' => lists.map {|list| list},
                                  'email' => email,
                                  'subscribe' => subscribe}.to_yaml)

  confirm_code = String.new
  aes_code.each_byte { |byte| confirm_code += ("%02x" % byte) }

  confirm_link = "http://#{$domain}/confirm/#{confirm_code}"

  body = "Liste(s) concernee(s) :\n"
  lists.each do |list|
    body += "\t#{list}@#{place.name}.#{$domain}\n"
  end
  body += "\n\nVeuillez cliquer sur le lien suivant pour confirmer : #{confirm_link}"
  body += "\n-- \n#{$domain}"

  Pony.mail(:to => email,
            :from => '#{$from}@#{$domain}',
            :subject => @subscribe ? 'Confirmation inscription' : 'Confirmation desinscription',
            :body => body)
end

# Actions

get '/confirm/:infos' do
  raw_infos = params['infos']
  aes_infos = raw_infos.scan(/../).map { |num| num.to_i(16) }.pack('c*')
  infos = YAML::load($aes.decrypt_string(aes_infos))


  @place = Place.new(infos['place'])
  @subscribe = infos['subscribe']

  @lists = Array.new

  infos['lists'].each do |name|
    @lists << List.new(name, "#{@place.name}.#{$domain}")
  end

  if @subscribe
    
  else

  end

  @page = 'place'
  builder :confirm
end

post '/:place/subscribe/?' do
  name = params[:place]
  @email = params[:email]
  @subscribe = params[:subscribe] == "Inscription" ? true : false
  @place = Place.new(params[:place])

  lists = []
  params.each_key do |list|
    if list.match(/list_(.+)/)
      lists << params[list]
    end
  end
  send_confirm(@place, lists, @email, @subscribe)

  @page = 'place'
  builder :place
end

# Views

get '/' do
  ml = MLServer.new
  match = request.host.match(/(.+)\.#{$domain}/)
  if match and $1 != 'www'
    redirect "http://#{request.host}/#{match[1]}"
  else
    @places = ml.places
    @page = 'home'
    builder :places
  end
end

get '/:place/?' do
  @email = ''
  @place = Place.new(params[:place])
  @page = 'place'
  builder :place
end

get '/:place/:ml/?' do
  @place = Place.new(params[:place])
  @list = List.new(params[:ml], "#{params[:place]}.#{$domain}")
  @archive = load_xhtml("views/archives/#{params[:place]}.#{$domain}/#{params[:ml]}/index.html")
  @page = 'list'
  builder :list
end

get '/:place/:ml/:date/:file?' do
  @place = Place.new(params[:place])
  @list = List.new(params[:ml], "#{params[:place]}.#{$domain}")
  @date = params[:date]
  @archive = load_xhtml("views/archives/#{params[:place]}.#{$domain}/#{params[:ml]}/#{params[:date]}/#{params[:file]}")
  @page = 'date'
  builder :list
end
