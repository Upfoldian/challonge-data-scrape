require 'JSON'

def calculate_elo_change(winner_elo, loser_elo)
	#Rn = Ro + C * (S - Se)
	expectedScore = 1.0 / ( 1 + 10 ** ( (loser_elo - winner_elo) / 400.0) )
	newRating = 50 * 1 * ( 1 - expectedScore )
	#puts newRating
	return newRating.floor
end


jsonFile = File.read('smash4results.json')

resultsHash = JSON.parse(jsonFile)

eloHash = {}

resultsHash["events"].each do |event|

	event["entrants"].each do |entrant|
		if !eloHash.include? entrant
			eloHash[entrant] = {:wins => 0,  :loses => 0, :totalSets => 0, :elo => 1200}
		end
	end

	event["results"].each do |result|

		winner = result["winner"]
		loser = result["loser"]
		winnerScore = result["winnerScore"]
		loserScore = result["loserScore"]
		total = winnerScore.to_i - loserScore.to_i

		[0..total].each do |x|
			ratingChange = calculate_elo_change(eloHash[winner][:elo], eloHash[loser][:elo])
			eloHash[winner][:elo]+=ratingChange
			eloHash[loser][:elo]-=ratingChange
		end

		eloHash[winner][:wins]+=winnerScore.to_i
		eloHash[loser][:loses]+=winnerScore.to_i
		eloHash[loser][:wins]+=loserScore.to_i
		eloHash[winner][:loses]+=loserScore.to_i
		eloHash[winner][:totalSets]+=1
		eloHash[loser][:totalSets]+=1
	end
end
eloArr = []
eloHash.each do |player|
	playerName = player.first
	elo = player.last[:elo]
	totalGames = player.last[:wins].to_i + player.last[:loses].to_i
	totalSets = player.last[:totalSets]
	eloArr.push [playerName, elo, totalSets, totalGames]
end
eloArr = eloArr.sort_by { |tuple| tuple[1].to_i}.reverse

eloArr.each {|x| puts "#{x[0]}, Elo: #{x[1]}, Sets Played: #{x[2]}, Games Played: #{x[3]}"}
puts ""

wlHash = {}
eloHash.each do |player|
	playerName = player.first
	wl = player.last
	if wl[:loses] == 0
		wlHash[playerName] = wl[:wins].to_f/1.0
	else
		wlHash[playerName] = ((wl[:wins].to_f/wl[:loses].to_f)*100).round / 100.00
	end
end

wlHash.sort_by { |k, v| v}.reverse.each do |x|
	puts "#{x[0]}, w/l ratio: #{x[1]}"
end
