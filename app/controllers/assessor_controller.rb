class AssessorController < ApplicationController

  before_action :set_scenario, only: [:home]

  # GET /scenarios
  def home
    @nearby_restaurants = Scenario.where(zomato_restaurant_id: eval(@scenario.nearby_restaurants))
  end

  # GET /sample.json
  def sample
    # response = RestClient.post 'https://api.textrazor.com', {'extractors' => 'entities,words,relations,senses', 'text' => "This place isn't good. Very small spread populated by underwhelming dishes. The naan was dry and thin--perhaps it had been hanging out with some local tortillas and picked up some bad habbits. The saag paneer was mediocre and the tandoori chicken was dry as a bone. All the dishes were run of the mill. Now for the interesting part! Somebody elses dishes and glass (complete with a straw that neither I or my companion never use) magically appeared on our table between trips to the buffet. I subsequently lost my appetite upon discovering an extra fork and realizing I may have not used my own! My partner's jacket was still at the table so we know we weren't sitting at the wrong table. Management was nice enough to replace my silverware and drink, but given the subpar food and my experience, I'll never go back."}, {'x-textrazor-key' => '0d6ca499a870c7b9e3b81b4933d8634a4c849fd01b41bfaee29f0b4f'}
    # response = JSON.parse response

    # res_id = eval(Scenario.where(primary: true).last.nearby_restaurants)
    # nearby_restaurants = Scenario.select('zomato_user_rating').where(zomato_restaurant_id: res_id).all
    # @ratings = {
    #               Not_Rated: 0,
    #               Poor: 0,
    #               Average: 0,
    #               Good: 0,
    #               Awesome: 0,
    #             }
    # nearby_restaurants.each do |rest|
    #   case rest.zomato_user_rating
    #     when 0
    #       @ratings[:Not_Rated] += 1
    #     when 0.1..2
    #       @ratings[:Poor] += 1
    #     when 2.1..3
    #       @ratings[:Average] += 1
    #     when 3.1..4
    #       @ratings[:Good] += 1
    #     when 4.1..5
    #       @ratings[:Awesome] += 1
    #   end
    # end

    @reviews = Review.select('id').where(restaurant_id: Scenario.where(primary: true).last.zomato_restaurant_id).all.as_json
    arr = []
    @reviews.each do |item| arr.push item['id'] end
    @reviews = arr
    @entities = Entity.where.not(property: '').where(review_id: @reviews).all

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
