require 'active_record'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
ActiveRecord::Base.logger = Logger.new(STDOUT)

class User < ActiveRecord::Base
  has_many :background_images
  KEY = "gDsgtEjVAwViYG72vXVg2A"
  SECRET = ENV['TWITTER_SECRET']
  
  def post_short
    if long?
      self.post.unpack("a141a*").first.force_encoding('utf-8').chop
    else
      self.post
    end
  end
  
  def long?
    self.post != self.post.unpack("a141a*").first.force_encoding('utf-8')
  end
  
  def consumer
    OAuth::Consumer.new(KEY, SECRET, {:site => "https://api.twitter.com", :scheme => :header})
  end
  
  def tweet
    Twitter.configure do |config|
      config.consumer_key       = KEY
      config.consumer_secret    = SECRET
      config.oauth_token        = self.token
      config.oauth_token_secret = self.secret
    end 
    Twitter.update("お金ください http://kanekure.ssig33.com/#{self.screen_name} #{self.account} #kanekure")
  rescue 
    nil
  end
  
  def message
    renderer = Redcarpet::Render::HTML.new(hard_wrap: true, filter_html: true)
    Redcarpet::Markdown.new(renderer, tables: true, gh_blockcode: true, fenced_code_blocks: true, autolink: true).render self.post
  end
end

class BackgroundImage < ActiveRecord::Base
end

