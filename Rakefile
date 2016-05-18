task :update do
  # Receive new tweets from Twitter
  output = run('ebooks archive davidcelis corpus/davidcelis.json 2>&1')
  new_tweets = output.match(/^Received (\d+ new tweets?)\Z/)
  exit unless new_tweets

  # Tokenize all tweets to update the model
  run('ebooks consume corpus/davidcelis.json')

  # Commit the changes and push to both GitHub and deis
  run("git commit -asm 'Update model with #{new_tweets[0]}'")
  run('git push origin master')
  run('git push deis master')
end

task default: :update

def run(command)
  puts "==> #{command}"
  `#{command}`
end
