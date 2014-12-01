require './lib/apikey.rb'

module ChallongeScrape

	Challonge::API.username = USER
	Challonge::API.key = APIKEY

	human = File.new("humanResults.txt", 'w')
	jsonFile = File.read("./json/smash4results.json")
	dataHash = JSON.parse(jsonFile)
	nameArr = dataHash["events"].map { |x| x["eventName"]}


	events = Challonge::Tournament.find(:all, :params => {:subdomain => 'sydneysmash'})

	puts "Starting..."
	events.each do |event|
		puts "Current Event: #{event.name}"
		next if nameArr.include? event.name

		currentEvent = {:eventName => "", :eventType => "", :startDate => "", :entrants => [], :results => []}

		currentEvent[:eventName] 	= event.name
		currentEvent[:eventType] 	= event.tournament_type
		currentEvent[:startDate] 	= event.started_at
		currentEvent[:eventURL] 	= event.full_challonge_url

		human.puts "Event Name: #{event.name}"
		human.puts "Event Type: #{event.tournament_type}"
		human.puts "Event Date: #{event.started_at}"
		human.puts "Event  URL: #{event.url}"	
		human.puts "Entrants: "

		event.participants(:all).each do |entrant| 
			human.puts "\t-#{entrant.name}"
			currentEvent[:entrants].push entrant.name
		end
		currentEvent[:entrants].sort!

		human.puts "\nMatches: "
		event.matches(:all).each do |match|
			#pretty gross but whatever
			scores = match.scores_csv.split(',')
			player1score 	= 0
			player2score 	= 0
			player1 		= match.player1.name
			player2 		= match.player2.name
			winner 			= ""
			loser 			= ""
			winnerScore 	= 0
			loserScore 		= 0

			scores.each do |score|
				playerScore = score.split('-')
				player1score += playerScore[0].to_i
				player2score += playerScore[1].to_i
			end

			if (player1score > player2score) 
				winner 		= player1
				winnerScore = player1score
				loser 		= player2
				loserScore 	= player2score
			else 
				winner 		= player2
				winnerScore = player2score
				loser 		= player1
				loserScore 	= player1score
			end
			score = "#{winnerScore}-#{loserScore}"
			human.puts "#{player1} vs #{player2} | Winner: #{winner} | Score: #{score}"

			resultHash = {:winner => "", :loser => "", :winnerScore => "", :loserScore => ""}

			resultHash[:winner] 		= "#{winner}"
			resultHash[:loser] 			= "#{loser}"
			resultHash[:winnerScore]	= "#{winnerScore}"
			resultHash[:loserScore] 	= "#{loserScore}"

			currentEvent[:results].push(resultHash)
		end
		human.puts " "
		dataHash["events"].push currentEvent

	end
	jsonFile = File.open("./json/smash4results.json", 'w')
	jsonFile.puts JSON.pretty_generate(dataHash, :indent => "\t")
	human.close
	jsonFile.close
end