class ProfileController < ApplicationController
  def show

      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless') # Run in headless mode
      

      driver = Selenium::WebDriver.for :chrome, options: options
      # driver.get(BASE_URL + '?' + URI.encode_www_form(filters.merge(limit: 50, page: page)))
      driver.get("https://www.ycombinator.com/companies/coinbase")
      
      sleep 5

      parsed_page_2 = Nokogiri::HTML(driver.page_source)
      
       
     
      # Close the driver
      driver.quit
     
      parsed_page_2 = Nokogiri::HTML(driver.page_source)
  
  

    website = "http://www.ycombinator.com"
    
    founders = parsed_page_2.css('.space-y-4 > div').map do |founder_element|
      name = founder_element.at_css('h3').text.strip
      linkedin_element = founder_element.at_css('a[href*="linkedin.com"]').values.first
      linkedin = linkedin_element['href'] if linkedin_element
      { name: name, linkedin: linkedin || "N/A" }
    end
  
    render json: { website: website || "N/A", founders: founders }
    
  end
    
end
