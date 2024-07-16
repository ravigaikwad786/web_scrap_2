class YCombinatorController < ApplicationController
  BASE_URL = 'https://www.ycombinator.com/companies'
  def scrape
    @companies = []

      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless') # Run in headless mode
      

      driver = Selenium::WebDriver.for :chrome, options: options
      
      url = generate_url

      driver.get(url)
      
      wait = Selenium::WebDriver::Wait.new(timeout: 10)
      
      wait.until { driver.find_element(css: '._results_86jzd_326') }
      
      sleep 5

      parsed_page_1 = Nokogiri::HTML(driver.page_source)
      
      driver.quit
     
      companies = parsed_page_1.css('._company_86jzd_338').map do |company_element|
        link = company_element['href']
        s_data = show(link)
        
        {
          name: company_element.at_css('._coName_86jzd_453').text.strip,
          location: company_element.at_css('._coLocation_86jzd_469').text.strip,
          description: company_element.at_css('._coDescription_86jzd_478').text.strip,
          YC_batch: company_element.at_css('._tagLink_86jzd_1023').text.strip,
          data: s_data
        }
      end
    save_to_csv(companies.take(params[:n].to_i))

    render json: companies.take(params[:n].to_i)
  end

  def show(link)

    response = HTTParty.get("https://www.ycombinator.com#{link}")
     
    parsed_page_2 = Nokogiri::HTML(response.body)
    
    website_element = parsed_page_2.at_css('.group a[href^="http"]')
    website = website_element['href'] if website_element
    
    founders = parsed_page_2.css('.space-y-5 > div').map do |founder_element|
      name = founder_element.at_css('.font-bold').text.strip
      linkedin_element = founder_element.at_css('a[href*="linkedin.com"]')
      linkedin = linkedin_element['href'] if linkedin_element
      { name: name, linkedin: linkedin || "N/A" }
    end
  
     { website: website || "N/A", founders: founders }
    
  end
  
  private

  def generate_url
    params = request.body.read
    filters = JSON.parse(params)["filters"]

    query_params = {}

    query_params[:batch] = filters["batch"] if filters["batch"].present?
    query_params[:industry] = filters["industry"] if filters["industry"].present?
    query_params[:regions] = filters["region"] if filters["region"].present?
    query_params[:tags] = filters["tag"] if filters["tag"].present?
    query_params[:team_size] = filters["company_size"] if filters["company_size"].present?
    query_params[:isHiring] = filters["is_hiring"] if filters["is_hiring"].present?
    query_params[:highlight_black] = filters["black_founded"] if filters["black_founded"].present?
    query_params[:highlight_latinx] = filters["hispanic_latino_founded"] if filters["hispanic_latino_founded"].present?
    query_params[:highlight_women] = filters["women_founded"] if filters["women_founded"].present?
    query_params[:top_company] = filters["top_company"] if filters["top_company"].present?
    query_params[:nonprofit] = filters["nonprofit"] if filters["nonprofit"].present?
    query_params[:highlight_women] = filters["women_founded"] if filters["women_founded"].present?

    url = "#{BASE_URL}?#{query_params.to_query}"
    url
  end


  def save_to_csv(companies)
    CSV.open("yc_companies.csv", "w") do |csv|
      csv << ["Name", "Location", "Description", "YC_batch", "Website", "Founders"]
      companies.each do |company|
        founders_info = company[:data][:founders].map do |founder|
          "#{founder[:name]} (#{founder[:linkedin]})"
        end.join(", ")

         csv << [
          company[:name], 
          company[:location], 
          company[:description], 
          company[:YC_batch], 
          company[:data][:website], 
          founders_info
        ]
      end
    end
    puts "Data saved to yc_companies.csv"     
  end
end
