require 'twitter_ebooks'

# This is an example bot definition with event handlers commented out
# You can define and instantiate as many bots as you like

# Information about a particular Twitter user we know
class UserInfo
  attr_reader :username

  # @return [Integer] how many times we can pester this user unprompted
  attr_accessor :pesters_left

  # @param username [String]
  def initialize(username)
    @username = username
    @pesters_left = 1
  end
end

class DcelisEbooks < Ebooks::Bot
  attr_accessor :original, :model, :model_path

  # Configuration here applies to all DcelisEbooks bots
  def configure
    self.consumer_key =    ENV['TWITTER_CONSUMER_KEY']
    self.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']

    # Users to block instead of interacting with
    self.blacklist = []

    # Range in seconds to randomize delay when bot.delay is called
    self.delay_range = 30..60

    @user_info = {}
  end

  def top(n)
    model.keywords.take(n)
  end

  def on_startup
    load_model!

    # 10% chance to tweet something in any 60 minute interval
    scheduler.every '1h' do
      tweet(model.make_statement) if rand > 0.90
    end
  end

  def on_message(dm)
    delay { reply(dm, model.make_response(dm.text)) }
  end

  def on_follow(user)
    # Follow a user back
    delay { follow(user.screen_name) }
  end

  def on_mention(tweet)
    # Become more inclined to pester a user when they talk to us
    user_info(tweet.user.screen_name).pesters_left += 1

    delay do
      reply(tweet, model.make_response(meta(tweet).mentionless, meta(tweet).limit))
    end
  end

  def on_timeline(tweet)
    return if tweet.retweeted_status?
    return unless can_pester?(tweet.user.screen_name)

    tokens = Ebooks::NLP.tokenize(tweet.text)

    interesting = tokens.find { |t| top(100).include?(t.downcase) }
    very_interesting = tokens.find_all { |t| top(20).include?(t.downcase) }.length > 2

    delay do
      if very_interesting
        favorite(tweet) if rand < 0.5
        retweet(tweet) if rand < 0.1

        if rand < 0.01
          user_info(tweet.user.screen_name).pesters_left -= 1
          reply(tweet, model.make_response(meta(tweet).mentionless, meta(tweet).limit))
        end
      elsif interesting
        favorite(tweet) if rand < 0.05

        if rand < 0.001
          user_info(tweet.user.screen_name).pesters_left -= 1
          reply(tweet, model.make_response(meta(tweet).mentionless, meta(tweet).limit))
        end
      end
    end
  end

  # Find information we've collected about a user
  # @param username [String]
  # @return [Ebooks::UserInfo]
  def user_info(username)
    @user_info[username] ||= UserInfo.new(username)
  end

  # Check if we're allowed to send unprompted tweets to a user
  # @param username [String]
  # @return [Boolean]
  def can_pester?(username)
    user_info(username).pesters_left > 0
  end

  # Only follow our original user or people who are following our original user
  # @param user [Twitter::User]
  def can_follow?(username)
    @original.nil? || username == @original || twitter.friendship?(username, @original)
  end

  def favorite(tweet)
    if can_follow?(tweet.user.screen_name)
      super(tweet)
    else
      log "Unfollowing @#{tweet.user.screen_name}"
      twitter.unfollow(tweet.user.screen_name)
    end
  end

  def on_follow(user)
    if can_follow?(user.screen_name)
      follow(user.screen_name)
    else
      log "Not following @#{user.screen_name}"
    end
  end

  private

  def load_model!
    return if @model

    @model_path ||= "model/#{original}.model"

    log "Loading model #{model_path}"
    @model = Ebooks::Model.load(model_path)
  end
end

# Make a new bot and attach it to an account
DcelisEbooks.new('dcelis_ebooks') do |bot|
  bot.access_token        = ENV['TWITTER_TOKEN']
  bot.access_token_secret = ENV['TWITTER_TOKEN_SECRET']

  bot.original = "davidcelis"
end
