require 'rubygems'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'

module Model
  
  adapter = DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3://db/my.db')
  adapter.resource_naming_convention = DataMapper::NamingConventions::Resource::UnderscoredAndPluralizedWithoutModule
  
  class Search
    include DataMapper::Resource
    
    property :id, Integer, :serial => true 
    property :term, String, :nullable => false
    property :created_at, DateTime
    property :updated_at, DateTime
  end
  
  class Hub
    include DataMapper::Resource
    
    property :id, Integer, :serial => true 
  end
  
  class Authority
    include DataMapper::Resource
    
    property :id, Integer, :serial => true 
  end
  
  
  
  
  
  # class Article
  #   include DataMapper::Resource
  # 
  #   property :id, Integer, :serial => true 
  #   property :title, String, :nullable => false
  #   property :body, Text, :nullable => false, :lazy => false, :length => (4..256)
  #   property :created_at, DateTime
  #   property :updated_at, DateTime
  #     
  #   has n, :comments
  #   belongs_to :category
  #   belongs_to :user
  #   
  #   validates_length :body, :minimum => 32
  # 
  #   def to_s
  #     @title
  #   end
  # end
  #   
  # class Category
  #   include DataMapper::Resource
  #   
  #   property :id, Integer, :serial => true
  #   property :name, String, :nullable => false, :unique => true
  #   
  #   has n, :articles
  #   
  #   validates_is_unique :name
  # 
  #   def to_s
  #     @name
  #   end
  # end
  #   
  # class Comment 
  #   include DataMapper::Resource
  #       
  #   property :id, Integer, :serial => true
  #   property :body, Text, :nullable => false, :lazy => false, :length => (4..128) 
  #   property :created_at, DateTime
  #   
  #   belongs_to :article
  #   
  #   def to_s
  #     @body
  #   end
  # end
  #   
  # class User
  #   include DataMapper::Resource
  #   
  #   property :id, Integer, :serial => true
  #   property :first, String
  #   property :last, String
  #   property :username, String
  #   property :password, String
  #   property :email, String, :format => :email_address
  #   property :created_at, DateTime
  #   property :updated_at, DateTime
  #   
  #   has n, :articles
  # 
  #   def to_s
  #     "#{@last}, #{@first} (#{@email})"
  #   end
  # end
  #   
  # def self.create_database
  #   puts "creating database (if needed)..."
  #   DataMapper.auto_migrate!
  # end  
  # 
  # def self.seed_database
  #   if Model::User.all.size == 0
  #     user = Model::User.new
  #     user.first = "Brian"
  #     user.last = "Sam-Bodden"
  #     user.email = "bsbodden@integrallis.com"
  #     user.username = "bsbodden"
  #     user.password = "letmein"
  #     user.save
  # 
  #     category_java = Model::Category.new
  #     category_java.name = "Java"
  #     category_java.save
  # 
  #     category_ruby = Model::Category.new
  #     category_ruby.name = "Ruby"
  #     category_ruby.save
  # 
  #     article_1 = Model::Article.new
  #     article_1.title = "Ruby Rocks!"
  #     article_1.body = "Ruby is Lisp without the eyebrows!"
  #     article_1.user = user
  #     article_1.category = category_java
  #     article_1.save
  # 
  #     comment_1_on_article_1 = Model::Comment.new
  #     comment_1_on_article_1.body = "This is comment 1 on article 1"
  #     comment_1_on_article_1.article = article_1
  #     comment_1_on_article_1.save
  # 
  #     comment_2_on_article_1 = Model::Comment.new
  #     comment_2_on_article_1.body = "This is comment 2 on article 1"
  #     comment_2_on_article_1.article = article_1
  #     comment_2_on_article_1.save
  # 
  #     article_2 = Model::Article.new
  #     article_2.title = "Java is fast!"
  #     article_2.body = "Java is no longer slow, the JVM rocks!"
  #     article_2.user = user
  #     article_2.category = category_java
  #     article_2.save
  # 
  #     comment_1_on_article_2 = Model::Comment.new
  #     comment_1_on_article_2.body = "This is comment 1 on article 2"
  #     comment_1_on_article_2.article = article_2
  #     comment_1_on_article_2.save
  # 
  #     comment_2_on_article_2 = Model::Comment.new
  #     comment_2_on_article_2.body = "This is comment 2 on article 2"
  #     comment_2_on_article_2.article = article_2
  #     comment_2_on_article_2.save 
  #   end    
  # end
end



