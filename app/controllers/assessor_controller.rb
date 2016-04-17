class AssessorController < ApplicationController

  before_action :set_scenario, only: [:home]

  # GET /scenarios
  def home
    nearby_list = eval(@scenario.nearby_restaurants)
    nearby_list.push @scenario.zomato_restaurant_id
    @ranked_list = Scenario.where(zomato_restaurant_id: nearby_list).order(ranking_score: :desc)
    @favorites = []
    @distance = []
    @ranked_list.each do |item|
      # Get the fav menu item for each restaurant
      reviews = Review.select('id').where(restaurant_id: item.zomato_restaurant_id).all.as_json
      arr = []
      reviews.each do |review| arr.push review['id'] end
      reviews = arr
      entity = Entity.where(review_id: reviews).where(sentiment_type: 'positive').order(sentiment: :desc)
      @favorites[item.zomato_restaurant_id] = entity.count != 0 ? entity.first.entity : 'Not available'
      # Get distance of each restaurant from primary restaurant
      response = RestClient.get "https://maps.googleapis.com/maps/api/distancematrix/json?origins=#{item.location_lat},#{item.location_lng}&destinations=#{@scenario.location_lat},#{@scenario.location_lng}&key=#{Rails.application.config.google_key}"
      response = JSON.parse(response)
      if response['status'] == 'OK' and response['rows'][0]['elements'][0]['status'] == 'OK'
        @distance[item.zomato_restaurant_id] = (response['rows'][0]['elements'][0]['distance']['value']*0.000621371).to_i.to_s
      else
        @distance[item.zomato_restaurant_id] = 'NA'
      end
    end

    # Get Neighborhood History
    @history = @scenario.comprehensive_rating_history

    #Food Quality
    @food_quality = @scenario.get_food_quality

    #Pop Stats
    @pop_stats = @scenario.get_pop_stats
    @pop_entities = {}
    @pop_entities[:white] = (@pop_stats[:whites]*100)/@pop_stats[:total]
    @pop_entities[:black] = (@pop_stats[:blacks]*100)/@pop_stats[:total]
    @pop_entities[:hispanic] = (@pop_stats[:hispanics]*100)/@pop_stats[:total]
    @pop_entities[:natives] = (@pop_stats[:american_natives]*100)/@pop_stats[:total]
    @pop_entities[:indian] = (@pop_stats[:indians]*100)/@pop_stats[:total]
    @pop_entities[:chinese] = (@pop_stats[:chinese]*100)/@pop_stats[:total]

  end

  # GET /sample.json
  def sample
    # @pop = Scenario.where(primary: true).first.get_pop_stats

    # response = RestClient.post 'https://api.textrazor.com', {'extractors' => 'entities,words,relations,senses', 'text' => "This place isn't good. Very small spread populated by underwhelming dishes. The naan was dry and thin--perhaps it had been hanging out with some local tortillas and picked up some bad habbits. The saag paneer was mediocre and the tandoori chicken was dry as a bone. All the dishes were run of the mill. Now for the interesting part! Somebody elses dishes and glass (complete with a straw that neither I or my companion never use) magically appeared on our table between trips to the buffet. I subsequently lost my appetite upon discovering an extra fork and realizing I may have not used my own! My partner's jacket was still at the table so we know we weren't sitting at the wrong table. Management was nice enough to replace my silverware and drink, but given the subpar food and my experience, I'll never go back."}, {'x-textrazor-key' => '0d6ca499a870c7b9e3b81b4933d8634a4c849fd01b41bfaee29f0b4f'}
    # response = JSON.parse response

    # @history = Scenario.where(primary: true).last.comprehensive_rating_history

    # arr = []
    # @reviews.each do |item| arr.push item['id'] end
    # @reviews = arr
    # @entities = Entity.where.not(property: '').where(review_id: @reviews).all

    # sentiments = '{"Hello":"wish", "there":[{"elsewhere":"google here"}]}'
    # sentiments = JSON.parse sentiments
    # @sent = ''
    # sentiments['there'][0].each {|k,v|
    #   @sent = k if v.include? 'google'
    # }

    # ent = []
    # if response['response']['entities'] && response['response']['sentences'] && response['response']['properties']
    #   response['response']['entities'].each do |entity|
    #     if entity['freebaseTypes'].to_s.include? 'food'
    #       prop_sentence = ''
    #       response['response']['properties'].each do |property|
    #         if (property['wordPositions'] & entity['matchingTokens']) == entity['matchingTokens']
    #           property['propertyPositions'].each do |prop_word_num|
    #             response['response']['sentences'].each do |sentence|
    #               sentence['words'].each do |word|
    #                 if word['position'] == prop_word_num
    #                   prop_sentence << ' ' << word['token']
    #                 end
    #               end
    #             end
    #           end
    #         end
    #       end
    #       ent.push({
    #                    'entity' => entity['matchedText'],
    #                    'property' => prop_sentence,
    #                    'entity_type' => entity['freebaseTypes']
    #                })
    #     end
    #   end
    # end
    # respond_to do |format|
    #   format.json { render :json => response}
    # end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
    def set_scenario
      id = params[:id].nil? ? Scenario.where(primary: true).last.id : params[:id]
      @scenario = Scenario.find(id)
    end

end
