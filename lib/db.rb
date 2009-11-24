require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'

module Model
  
  db_dir = File.expand_path(File.dirname(__FILE__)+"/../db")

  adapter = DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{db_dir}/five_to_follow.db")
  adapter.resource_naming_convention = DataMapper::NamingConventions::Resource::UnderscoredAndPluralizedWithoutModule
  
  class User
    include DataMapper::Resource
    
    property :id, Serial
    property :twitter_id, String, :nullable => false, :index => :unique
    property :email, String, :format => :email_address
    property :created_at, DateTime
    property :updated_at, DateTime
    
    def to_s
      "#{@twitter_id} (#{@email})"
    end
  end
  
  class Profile
    include DataMapper::Resource

    property :id, Serial
    property :twitter_id, String, :nullable => false, :index => :unique
    property :grade, Float, :default => 0.0
    property :image, String, :length => 512
    property :confirmed, Boolean, :default => false
  end
    
  class Query
    include DataMapper::Resource
    
    property :id, Serial
    property :terms, String, :nullable => false, :index => :unique
    property :hits, Integer
    property :last_request, DateTime
    property :last_evaluation, DateTime
    property :exhaustive, Boolean, :default => false
    property :version, Integer
    property :created_at, DateTime
    property :updated_at, DateTime
    
    has n, :authority_scores, :order => [ :score.asc ]
    
    def top_authority_scores(how_many=5)
      authority_scores(:limit => how_many)
    end
    
    def to_s
      "#{@terms} (h:#{@hits}, v:#{@version})"
    end
  end
  
  class HubScore
    include DataMapper::Resource
    
    property :id, Serial
  
    property :twitter_id, String, :nullable => false
    property :score, Integer, :nullable => false
    property :version, Integer
    
    belongs_to :query 
    
    def profile
      Profile.first(:twitter_id => twitter_id)
    end
  end
  
  class AuthorityScore
    include DataMapper::Resource
    
    property :id, Serial
  
    property :twitter_id, String, :nullable => false
    property :score, Integer, :nullable => false
    property :version, Integer
    
    belongs_to :query
    
    def profile
      Profile.first(:twitter_id => twitter_id)
    end
  end
  
  DataMapper.auto_upgrade!
end



