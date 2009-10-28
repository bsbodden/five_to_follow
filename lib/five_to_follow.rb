require 'rubygems'
require 'trellis'

include Trellis

module FiveToFollow
  class FiveToFollowApp < Application
    home :search
  end

  class Search < Page
    pages :search_results

    template do
      xhtml_strict {
        head {
          title "Welcome to FiveToFollow"
        }
        body {
          h1 "Enter a search term to find folks to follow..."
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
