class Controller < Sinatra::Base

  @@hc = HTTPClient.new

  get '/' do
    erb :index
  end

  # Channel Index
  get %r{^/([a-zA-Z\-]+)$} do |channel|
    @channel = channel
    erb :channel_index
  end

  # Redirect to today
  get %r{^/([a-zA-Z\-]+)/today$} do |channel|
    redirect "#{SiteConfig['base']}/#{channel}/#{DateTime.now.strftime('%Y-%m-%d')}"
  end

  # Channel view for one day
  get %r{^/([a-zA-Z\-]+)/([0-9]{4}-[0-9]{2}-[0-9]{2})} do |channel, date|
    @channel = channel
    @date = date
    erb :channel_date
  end

  get '/auth/:provider/callback' do

    # Check if the user is a member of the required organization
    orgs = JSON.parse(@@hc.get("https://api.github.com/user/orgs", nil, {
      'Authorization' => "Bearer #{request.env['omniauth.auth']['credentials']['token']}"
    }).body)

    authorized = false

    if orgs 
      org_ids = orgs.map{|o| o['login']}
      if (org_ids & SiteConfig['github']['orgs']).length > 0
        authorized = true
      end
    end

    if authorized
      session[:username] = request.env['omniauth.auth']['extra']['raw_info']['login']
      redirect "#{SiteConfig['base']}/"
    else
      erb "<h1>Not Authorized</h1>"
    end
  end

end
