class Review < ActiveRecord::Base

  after_save :load_entities

  # Get entities from Text Razor
  def load_entities
    response = RestClient.post 'https://api.textrazor.com', {'extractors' => 'entities,words,relations', 'text' => self.review_text}, {'x-textrazor-key' => '8d46cef8b85b441d0833998d2857bad458d7610728e318adc314f683'}
    response = JSON.parse response

    if response['response']['entities'] && response['response']['sentences'] && response['response']['properties']
      response['response']['entities'].each do |entity|
        if entity['freebaseTypes'].to_s.include? 'food'
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
          if Entity.where(property: prop_sentence, review_id:  self.id).count == 0
            new_entity.save
          else
            Entity.where(property: prop_sentence, review_id:  self.id).each do |old_entity|
              if old_entity.entity.include? new_entity.entity
                new_entity.destroy!
              else if new_entity.entity.include? old_entity.entity
                  old_entity.destroy!
               end
              end
            end
            new_entity.save unless new_entity.destroyed?
          end
        end
      end
    end
  end
end
