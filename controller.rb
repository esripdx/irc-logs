class Controller < Sinatra::Base

  @@hc = HTTPClient.new

  def require_login
    if session[:username] == nil
      redirect "#{SiteConfig['base']}/auth/github"
    end
  end

  get '/' do
    erb :index
  end

  # Channel Index
  get %r{^/([a-zA-Z\-]+)$} do |channel|
    require_login

    @channel = channel
    erb :channel_index
  end

  # Redirect to today
  get %r{^/([a-zA-Z\-]+)/today$} do |channel|
    if params[:bookmark]
      @message = "<div class=\"content\"><a href=\"#{ _l '/'+channel+'/today#bottom' }\">Click this, then bookmark</a></div>"
      erb :bookmark
    else
      if request.env['HTTP_REFERER'] && request.env['HTTP_REFERER'].match(/bookmark=true/)
        @message = "<div class=\"content\">Bookmark this page or add to your home screen! When you visit it again, it will redirect you to today's logs.</div>"
        erb :bookmark
      else
        redirect "#{SiteConfig['base']}/#{channel}/#{DateTime.now.strftime('%Y-%m-%d')}"
      end
    end
  end

  # Channel view for one day
  get %r{^/([a-zA-Z\-]+)/([0-9]{4})-([0-9]{2})-([0-9]{2})} do |channel, year, month, day|
    require_login

    @channel = DB[:channels].filter(:channel => "##{channel}").first

    if @channel
      @tz = Timezone::Zone.new :zone => @channel[:timezone]

      @current_date = "#{year}-#{month}-#{day}"

      # Get the unix timestamp of the beginning of the day
      @date_from = DateTime.new year.to_i, month.to_i, day.to_i, 0, 0, 0, Rational(@tz.utc_offset,86400)
      @ts_from = @date_from.to_time.to_i

      # Get the unix timestamp of the end of the day
      @date_to = DateTime.new year.to_i, month.to_i, day.to_i, 23, 59, 59, Rational(@tz.utc_offset,86400)
      @ts_to = @date_to.to_time.to_i

      @date_title = @date_from.strftime('%B %-d, %Y')

      @logs = DB[:irclog].filter(:channel => @channel[:channel], :timestamp => (@ts_from)..(@ts_to))

      # Find next/prev dates
      yesterday = @date_from - 1
      tomorrow = @date_from + 1

      @yesterday = yesterday.strftime '%Y-%m-%d'
      if tomorrow > DateTime.now
        @tomorrow = nil
      else
        @tomorrow = tomorrow.strftime '%Y-%m-%d'
      end

      erb :channel_date
    else
      erb :error
    end
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

  def _l(link) 
    "#{SiteConfig['base']}#{link}"
  end

  def format_line(line)
    data = nil
    classes = ['h-entry']

    nick = line[:nick]

    # First escape any html tags in the input
    html = CGI.escapeHTML line[:line]

    if line[:type] == '64'
      classes << 'msg-join'
      html = line[:line].gsub(/^[\w\|]+ /, '')
    elsif data = line[:line].match(/^https?:\/\/twitter.com\/([^ ]+) /)
      classes << 'msg-twitter'
      nick = "@#{data[1]}"
      html = CGI.escapeHTML data[2]
    elsif data = line[:line].match(/\[@([^\]]+)\] (.+) \((http:\/\/twtr\.io\/[^ ]+|https:\/\/twitter\.com\/[^ ]+)\)/)
      classes << 'msg-twitter'
      classes << 'msg-retweet' if data[2].match(/^RT /)
      nick = "@#{data[1]}"
      html = CGI.escapeHTML(data[2]) + " " + data[3]
    end

    # Match hyperlinks
    result = html.gsub! %r{(https?://[^\s]+(?<!\)))}, '<a href="\1">\1</a>'

    # Match twitter usernames
    html.gsub! /(?<![a-z0-9_])@([a-z0-9_]+)/i, '<a href="https://twitter.com/\1">@\1</a>'

    partial :irc_line, :locals => {line: line, nick: nick, html: html, data: data, classes: classes}
  end

  def partial(page, options={})
    erb :"partials/#{page}", options.merge!(:layout => false)
  end

end
