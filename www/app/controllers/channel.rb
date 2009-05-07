class Channel < Application
    
    def index(channel)
      @channel = CGI.unescape(channel)
      @title = "\##{@channel} - irc.gimite.net"
      @client_url = "/client?utf8=" + CGI.escape("\##{@channel}")
      date_strs = Dir[channel_dir(@channel) + "/*.txt"].
        map(){ |s| s.slice(/(\d+)\.txt/, 1) }.
        sort().reverse()
      @items = []
      for date_str in date_strs
        @items.push({
          :date => str_to_date(date_str),
          :url => "/channel/%s/archive/%s" % [CGI.escape(@channel), date_str],
        })
      end
      render()
    end
    
    def log(channel, date)
      @channel = CGI.unescape(channel)
      @date_str = CGI.unescape(date)
      @date = str_to_date(@date_str)
      @prev_date = @date - 1
      @prev_date_url = log_url(@channel, @prev_date)
      @next_date = @date + 1
      @next_date_url = @next_date > Date.today ? nil : log_url(@channel, @next_date)
      @title = "%s - \#%s - irc.gimite.net" % [@date.strftime("%Y/%m/%d"), @channel]
      @channel_url = "/channel/" + CGI.escape(@channel)
      log_path = "%s/%s.txt" % [channel_dir(@channel), @date_str]
      @log = []
      if File.exist?(log_path)
        File.foreach(log_path) do |line|
          @log.push(IRCMessage.new(@channel, line))
        end
      end
      render()
    end
    
  private
    
    def log_url(channel, date)
      "/channel/%s/archive/%s" % [CGI.escape(channel), date_to_str(date)]
    end
    
    def channel_dir(channel)
      return "../deborah/gimite.net/log/%s" % CGI.escape("\##{@channel}")
    end
    
    def date_to_str(date)
      return format("%04d%02d%02d", date.year, date.month, date.day)
    end
    
    def str_to_date(str)
      str =~ /^(\d\d\d\d)(\d\d)(\d\d)$/
      return Date.new($1.to_i(), $2.to_i(), $3.to_i())
    end
    
end


class IRCMessage
    
    def initialize(channel, line)
      (@time_str, @from, @command, *@args) = line.chomp().split(/\t/)
      case @command
        when "PRIVMSG"
          @from_str = "<#{@from}>"
          @body = @args[0]
          @body_class = "privmsg"
        when "NOTICE"
          @from_str = "(#{@from})"
          @body = @args[0]
          @body_class = "notice"
        when "JOIN"
          @message = "*** #{@from} has joined channel \##{channel}"
        when "PART"
          @message = "*** #{@from} has left channel \##{channel}"
        when "QUIT"
          arg_str = @args[0] ? " (#{@args[0]})" : ""
          @message = "*** #{@from} has left IRC#{arg_str}"
        when "NICK"
          @message = "*** #{@from} is now known as #{@args[0]}"
        when "MODE"
          @message = "*** New mode for \##{channel} by #{@from}: #{@args[0]} #{@args[1]}"
        when "TOPIC"
          @message = "*** New topic on \##{channel} by #{@from}: #{@args[0]}"
        when "KICK"
          arg_str = @args[1] ? " (#{@args[1]})" : ""
          @message = "*** #{@args[0]} was kicked off from \##{channel} by #{@from}#{arg_str}"
        else
          raise("unknown command: #{@command}")
      end
    end
    
    attr_reader(:time_str, :from_str, :body, :message, :body_class)
    
end