class User < ActiveRecord::Base
end

class App < Sinatra::Base
  configure do
    register Sinatra::ActiveRecordExtension
    use Rack::Session::Cookie, expire_after: 3600, secret: "salt"
  end

  helpers do
    def csrf_meta_tag
      Rack::Csrf.csrf_metatag(env)
    end

    def param_str(parameters)
      parameters.map { |key, value| key.to_s + "=" + CGI.escape(value.to_s) }.join("&")
    end

    def http_get(endpoint, parameters = {})
      uri = URI.parse(parameters.length > 0 ? endpoint + "?" + param_str(parameters) : endpoint)
      JSON.parse(Net::HTTP.get_response(uri).body, symbolize_names: true)
    rescue
      { error: true }
    end

    def http_post(endpoint, parameters)
      uri = URI.parse(endpoint)
      JSON.parse(Net::HTTP.post_form(uri, parameters).body, symbolize_names: true)
    rescue
      { error: true }
    end

    def endpoint_of(service, action)
      "http://" << service << "/" << action
    end
  end

  post "/users" do
    content_type :json
    result = { error: false }

    json_params = JSON.parse(request.body.read, symbolize_names: true)
    user_name = json_params[:users][:name]
    user_description = json_params[:users][:description]
    user = User.new(name: user_name, description: user_description)

    if user.save
      result[:users] ||= []
      result[:users] << user
    else
      status 400
      result[:error_messages] = user.errors.messages
    end

    result.to_json
  end

  get "/users" do
    content_type :json
    result = { error: false }


    users = User.all
    result[:users] = users

    result.to_json
  end

  patch "/users" do
    content_type :json
    result = { error: false }

    json_params = JSON.parse(request.body.read, symbolize_names: true)
    user_name = json_params[:users][:name]
    user_description = json_params[:users][:description]


    result.to_json
  end

  delete "/users" do
    content_type :json
    result = { error: false }

    json_params = JSON.parse(request.body.read, symbolize_names: true)
    user_name = json_params[:users][:name]
    user_description = json_params[:users][:description]


    result.to_json
  end
end
