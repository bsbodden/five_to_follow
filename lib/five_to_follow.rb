require 'rubygems'
require 'trellis'

include Trellis

module FiveToFollow
  # DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3://db/my.db')
  
  class FiveToFollowApp < Application
    home :search
  end

  class Search < Page
    pages :search_results
    
    def on_submit_from_search
      term = params[:search_term]
      logger.info "searching with term #{term}"
      self
    end

    template do
      tag!(:html, 
           :xmlns => "http://www.w3.org/1999/xhtml", 
           "xml:lang" => "en", 
           :lang => "en",
           "xmlns:trellis" => "http://trellisframework.org/schema/trellis_1_0_0.xsd") {
        head {
          title "Welcome to FiveToFollow"
        }
        body {
          h1 "Enter a search term to find folks to follow..."
          text %[<trellis:form tid="search" method="post">]
          p {
            text %[<trellis:text_field tid="term"/>]
            text %[<trellis:submit tid="title" value="Search"/>]
          }
          text %[</trellis:form>]
        }
      }
    end
  end

  class SearchResults < Page
    pages :search

    template do
      xhtml_strict {
        head {
          title "Twitter Users Found..."
        }
        body {
          h1 "For the term 'blah' we found"
        }
      }
    end
  end

  class Login < Page
    pages :settings

    template do
      xhtml_strict {
        head {
          title "Login to FiveToFollow"
        }
        body {
          h1 "Login Fields go here!"
        }
      }
    end
  end

  class Settings < Page

    template do
      xhtml_strict {
        head {
          title "Account Settings"
        }
        body {
          h1 "Account Settings Fields go here!"
        }
      }
    end
  end

  if __FILE__ == $PROGRAM_NAME
    web_app = FiveToFollowApp.new
    web_app.start 3000
  end
end
