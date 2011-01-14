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
require 'i18n'

$config = YAML.load_file("config.yaml")
$config.each do |key, value|
  eval("$#{key}='#{value}'")
end

$aes = Crypt::Rijndael.new($aes_key)

path=File.dirname(__FILE__)
I18n.load_path += Dir[ File.join(path, 'locales', '*.{rb,yml}') ]
I18n.default_locale = $locale

class MLServer
  def lists
    lists = []
    $config['lists'].each do |list|
      lists << List.new(list, $domain)
    end
    return lists
  end
end

class List
  include Comparable

  attr_reader :name, :domain

  def List.email?(email)
    TMail::Address.parse(email)
    true
  rescue
    false
  end

  def List.empty?(name)
    !File.exists?("views/archives/#{name}/pipermail.pck")
  end

  def initialize(name, domain)
    @name = name
    @domain = domain
  end

  def <=>(other)
    @name <=> other.name
  end

  def ==(other)
    @domain = other.domain and @name == other.name
  end

  def members
    members = []
    list = Escape.shell_command(@name)
    `cd '#{$mailman_dir}' && bin/list_members #{list}`.split("\n").each do |line|
      members << line
    end
    return members
  end

  def subscribe(email)
    list = Escape.shell_command(@name)
    `cd '#{$mailman_dir}' && echo #{Escape.shell_command(email)} | bin/add_members -w n -r - #{list}`
  end

  def unsubscribe(email)
    list = Escape.shell_command(@name)
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

# Actions

get '/confirm/:infos' do
  raw_infos = params['infos']
  aes_infos = raw_infos.scan(/../).map { |num| num.to_i(16) }.pack('c*')
  infos = YAML::load($aes.decrypt_string(aes_infos))

  @subscribe = infos['subscribe']

  @lists = []
  infos['lists'].each do |name|
    @lists << List.new(name, $domain)
  end

  @lists.each do |list|
    if @subscribe
      list.subscribe(infos['email'])
    else
      list.unsubscribe(infos['email'])
    end
  end

  @page = 'lists'
  builder :confirm
end

post '/subscribe/?' do
  @email = params[:email]
  @subscribe = params[:subscribe] == I18n.t("sub") ? true : false

  lists = []
  params.each_key do |list|
    if list.match(/list_(.+)/)
      lists << params[list]
    end
  end

  aes_code = $aes.encrypt_string({'lists' => lists.map {|list| list},
                                  'email' => @email,
                                  'subscribe' => @subscribe}.to_yaml)

  confirm_code = String.new
  aes_code.each_byte { |byte| confirm_code += ("%02x" % byte) }

  confirm_link = "http://#{$domain}/confirm/#{confirm_code}"

  body = "#{I18n.t "lists"} :\n"
  lists.each do |list|
    body += "\t#{list}@#{$domain}\n"
  end
  body += "\n\n#{I18n.t "confirm"} : #{confirm_link}"
  body += "\n\n#{I18n.t "confirm_comment"}"
  body += "\n-- \n#{$domain}"

  Pony.mail(:to => @email,
            :from => "#{$from}@#{$domain}",
            :subject => @subscribe ? I18n.t("confirm_sub") : I18n.t("confirm_unsub"),
            :body => body)

  @ml = MLServer.new
  @page = 'home'
  builder :lists
end

# Views

get '/' do
  @ml = MLServer.new
  @page = 'home'
  builder :lists
end

get '/robot.txt' do
  File.open('robot.txt').read
end

get '/:list/?' do
  @list = List.new(params[:list], $domain)
  @archive = load_xhtml("views/archives/#{@list.name}/index.html")
  @page = 'list'
  builder :list
end

get '/:ml/:date/:file?' do
  @list = List.new(params[:ml], $domain)
  @date = params[:date]
  @archive = load_xhtml("views/archives/#{@list.name}/#{params[:date]}/#{params[:file]}")
  @page = 'date'
  builder :list
end
