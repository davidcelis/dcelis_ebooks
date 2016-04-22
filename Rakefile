task :update do
  # Receive new tweets from Twitter
  run('ebooks archive davidcelis corpus/davidcelis.json')

  # Tokenize all tweets to update the model
  output = run('ebooks consume corpus/davidcelis.json')
  new_tweets = output.match(/^Received (\d+ new tweets?)$/)

  # Commit the changes and push to both GitHub and deis
  exit unless new_tweets
  run("git commit -asm 'Update model with #{new_tweets[1]}'")
  run('git push origin master')
  run('git push deis master')
end

task default: :update

def run(command)
  puts "==> #{command}"
  `#{command}`
end
