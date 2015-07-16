require "pg"
require "http/client"
require "json"
require "webmock"

DB_URL = ENV["DATABASE_URL"]? || "postgresql://localhost/prohub_api_development"
DB = PG.connect(DB_URL)

module GetDomainPatternToofr
  def self.perform(contact_id)
    mock_toofr_get_domain_pattern

    domain = DB.exec(
      {PG::NilableString},
      "select domain from contacts where id = '#{contact_id}'"
    ).rows.first[0]

    response = HTTP::Client.get("https://toofr.com/api/get?key=#{api_key}&domain=#{domain}")

    pattern = Response.from_json(response.body).response.description

    domain = DB.exec(
      "UPDATE contacts SET domain_pattern = '#{pattern}' WHERE contacts.id = '#{contact_id}'"
    )

  end

  def self.api_key
    "40f1a98bb171c50d1e17fa9d64379351"
  end

  def self.mock_toofr_get_domain_pattern
    json = "{\"response\":{\"domain_data\":[],\"scrape\":{\"indexed\":4,\"alexa\":{\"alexa_us\":\"20085\"}},\"domain\":\"gonitro.com\",\"description\":\"first.last\",\"patterns\":[\"first.last\",\"first_last\",\"firstlast\",\"first-last\"]}}"
    WebMock.stub(:get, "toofr.com/api/get?key=#{api_key}&domain=gonitro.com")
      .with(headers: {"Host" => "toofr.com"})
      .to_return(status: 200, body: json)
  end

end

class Domain
  json_mapping({
    description: String
  })
end

class Response
  json_mapping({
    response: Domain
   })
end

GetDomainPatternToofr.perform("fffc8764-19e3-4818-a12e-b9dafb8e2a03")
