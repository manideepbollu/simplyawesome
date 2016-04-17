class Review < ActiveRecord::Base

  before_save :get_rating_text

  after_save :load_entities

  before_destroy {
    Entity.where(review_id: self.id).destroy_all
  }

  # Make sure review has rating text
  def get_rating_text
    if self.rating_text == 'Not rated'
      sentiments = RestClient.get "http://gateway-a.watsonplatform.net/calls/text/TextGetTextSentiment?apikey=#{Rails.application.config.alchemy_key}&text=#{URI.encode(self.review_text)}&outputMode=json"
      sentiments = JSON.parse sentiments
      if sentiments['status'] == 'OK'
        self.rating_text = sentiments['docSentiment']['type'].capitalize
        self.review_rating = (self.rating_text == 'Positive' ? 4 : 2)
      end
    end
  end

  # Get entities from Text Razor
  def load_entities
    response = RestClient.post 'https://api.textrazor.com', {'extractors' => 'entities,words,relations', 'text' => self.review_text}, {'x-textrazor-key' => Rails.application.config.text_razor_key}
    response = JSON.parse response

    sentiments = RestClient.get "http://gateway-a.watsonplatform.net/calls/text/TextGetRankedKeywords?apikey=#{Rails.application.config.alchemy_key}&text=#{URI.encode(self.review_text)}&outputMode=json&sentiment=1"
    sentiments = JSON.parse sentiments
    if sentiments['status'] == 'OK'
      if response['response']['entities'] && response['response']['sentences'] && response['response']['properties']
        response['response']['entities'].each do |entity|
          if entity['freebaseTypes'].to_s.include? 'food'
            sentiments['keywords'].each do |keyword|
              if keyword['text'].include? entity['matchedText']
                prop_sentence = ''
                response['response']['properties'].each do |property|
                  if (property['wordPositions'] & entity['matchingTokens']) == entity['matchingTokens']
                    property['propertyPositions'].each do |prop_word_num|
                      response['response']['sentences'].each do |sentence|
                        sentence['words'].each do |word|
                          if word['position'] == prop_word_num
                            prop_sentence << ' ' << word['token']
                          end
                        end
                      end
                    end
                  end
                end
                new_entity = Entity.new
                new_entity.entity = entity['matchedText']
                new_entity.entity_type = entity['freebaseTypes'].to_s
                new_entity.review = self
                new_entity.property = prop_sentence
                new_entity.sentiment = keyword['sentiment']['score']
                new_entity.sentiment_type = keyword['sentiment']['type']
                new_entity.save
              end
            end
          end
        end
      end
    end
  end
end
