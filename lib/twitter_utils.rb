module FiveToFollow
  class TwitterClient
    
    TWITTERLAND_API_KEY = "integrallis-3255"
    
    attr_accessor :logger
    
    def initialize
      @twitterers = {}
      @client = Grackle::Client.new()
    end
    
    def search(term)
      @client[:v1].search? :q => term, :rpp => 100 # results_per_page 
    end
    
    def next_page(response)
      q, max_id, page = response.next_page.match(/\?page=(\d+)&max_id=(\d+)&rpp=100&q=(\S+)/).to_a.reverse
      @client[:v1].search? :q => q, :page => page, :max_id => max_id, :rpp => 100
    end
    
    def get_user(tweeter_name, tweet, options = {})
      user = nil
      proceed = options[:check_user] ? is_twitter_user?(tweeter_name) : true
      if proceed
        @logger.debug "#{tweeter_name} ===> TEXT: #{tweet.text}, FROM: #{tweet.from_user}, IMAGE: #{tweet.profile_image_url})"
        user = @twitterers[tweeter_name] 
        unless user
          user = OpenStruct.new(:user => tweeter_name)
          # options
          user.grade = Twitterland::TwitterGrader.grade(tweeter_name, TWITTERLAND_API_KEY) if options[:with_grade]
        
          # add to the in memory hash
          @twitterers[tweeter_name] = user
        end  
        unless user.image
          user.image = tweet.profile_image_url if tweeter_name == tweet.from_user
        end
        @logger.debug "user ==> #{user.user}, grade ==> #{user.grade}"
      end
      user  
    end   
    
    def is_twitter_user?(tweeter_name)
      Net::HTTP.get_response(URI.parse("http://twitter.com/#{tweeter_name}"))['status'] == "200 OK"
    end
  end
end